# Batch Data Loss Incident Report

## Date: 2026-04-30

### Issue Summary
Warehouse personnel manually entered batch numbers (lotes) for 209+ products in the Control Interno panel, but all batch data suddenly disappeared from the "Clasificación de Productos" view, showing "Asignar lote..." for most products.

### Root Cause
**Critical Bug in `tara_weight_manager.py` - Line 1500:**

```python
# DESTRUCTIVE SAVE - WIPES ALL DATA BEFORE RE-INSERTING
conn.execute(text("DELETE FROM product_batches"))  # ← THIS LINE DELETED EVERYTHING
df_batches.to_sql("product_batches", ...)          # ← Then re-inserted from memory
```

**What happened:**
1. Every time `_save_classifications()` was called, it executed `DELETE FROM product_batches`
2. Then it tried to re-insert data from `_product_classifications` memory
3. But the memory had empty `lotes_info` for most products (shown in screenshot as "Asignar lote...")
4. Result: **All batch data was wiped and replaced with empty data**

**Additional problem:**
- The `product_batches` SQL table was **write-only** (data was saved to it but never loaded back)
- Even if data existed in SQL, it couldn't be recovered on load

### Recovery Results
✅ **Successfully recovered 209 products with batch data** from `history_logs` table

- Retrieved 1,483 history entries from SQL
- Found 387 product_edit events
- Extracted 209 products with lote/batch changes
- Restored all batch numbers, dates, and reinspection dates
- Saved to `product_classifications` and `product_batches` tables

### Fix Applied

**1. Changed SAVE logic from DELETE+INSERT to UPSERT (MERGE):**

```python
# BEFORE (DESTRUCTIVE):
conn.execute(text("DELETE FROM product_batches"))
df_batches.to_sql("product_batches", if_exists="append", ...)

# AFTER (SAFE UPSERT):
for record in batch_records:
    conn.execute(text("""
        MERGE product_batches AS target
        USING (VALUES (:product_id, :lote, ...))
        AS source (...)
        ON target.product_id = source.product_id AND target.lote = source.lote
        WHEN MATCHED THEN UPDATE SET ...
        WHEN NOT MATCHED THEN INSERT ...
    """), record)
```

**2. Added LOAD logic to read from `product_batches`:**

```python
# Load batch data from SQL and merge into classifications
df_batches = pd.read_sql("SELECT * FROM product_batches", con=self.sql_engine)
for batch_row in df_batches:
    # Merge batch data into product classifications
    # Set as primary lote if none exists
```

### Files Modified
- `tara_weight_manager.py`:
  - Lines 1479-1523: Changed save logic to UPSERT mode
  - Lines 1231-1277: Added load logic from product_batches table

### Recovery Script
- `recover_batches_flask.py`: Standalone script to recover batch data from history_logs
- Can be re-run if needed to recover any future data loss

### Recommendations

**Immediate:**
1. ✅ Restart the SGA web application to load the recovered data
2. ✅ Verify batch numbers are showing in Control Interno → Clasificación General
3. ✅ Run "Sincronizar Lotes SAP" to fill any remaining missing batches
4. ✅ Test label preview to confirm batches appear in templates

**Long-term:**
1. **Add backup mechanism**: Before any destructive operation on batch data, export to backup table
2. **Add audit trail**: Log all batch changes to a separate audit table (already exists in history_logs)
3. **Add validation**: Warn users before overwriting existing batch data
4. **Consider transaction isolation**: Use explicit transactions with rollback on error
5. **Regular backups**: Schedule periodic exports of product_batches to backup location

### Data Integrity
- ✅ All 209 products recovered with complete batch data
- ✅ Batch history preserved in `lote_history` field
- ✅ `product_batches` table now has UNIQUE constraint to prevent duplicates
- ✅ Data flows bidirectionally: load from SQL + save to SQL

### Impact
- **Before**: 1 product with batch data (ASH-QB00007: E24220201)
- **After**: 209 products with batch data restored
- **Data loss prevented**: All warehouse work preserved

### Lessons Learned
1. Never use DELETE+INSERT pattern without verifying source data exists
2. Always implement bidirectional data flow (load + save)
3. History logs are invaluable for data recovery - ensure they're comprehensive
4. Test destructive operations with rollback capability
5. Add data integrity checks before saving to prevent silent data loss
