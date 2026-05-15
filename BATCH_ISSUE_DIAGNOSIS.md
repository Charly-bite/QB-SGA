# Batch Number Display Issue - Diagnostic Report

## Summary
Batch numbers (lotes) are disappearing from the template creation/preview in the SGA Web application.

## How Batch Data Flows Through the System

### 1. **Data Sources** (in priority order):
   - **Control Interno Database** (`product_classifications` table/JSON):
     - Stored in `TaraWeightManager._product_classifications`
     - Contains: `lote`, `lote_date`, `lote_reinspection_date`, `lotes_info`
     - Location: SQL Server `SGA_Database.product_classifications` OR JSON fallback
   
   - **SAP HANA** (via `sap_connector.py`):
     - Query from `OBTN` (batches table) + `OITM` (items)
     - Method: `get_all_latest_batches()` returns `{item_code: {batch_number, manufacturing_date, expiry_date}}`
   
   - **User Overrides** (from Control Interno history logs):
     - Method: `_extract_user_lote_overrides()` in `control_interno.py`
     - Has higher priority than SAP data

### 2. **Data Resolution Path**:

```
Queue Add (labels.py:385)
  → get_batch_and_tare(code, quantity)
    → TaraWeightManager.get_classification(product_code)
      → Returns: lote, lote_date, lote_reinspection_date
    → Apply user overrides from history (if any)
    
Template Preview (templates.py:154)
  → api_product_data(product_id)
    → product.get('batch_number', '000000')  ← LINE 235
    → Maps to: batch_barcode, lote_value
```

### 3. **Template Fields** (available in designer):
   - `lote_value`: Text field showing batch number
   - `batch_barcode`: Barcode for batch number
   - `lote_label`: Static "LOTE:" text

## Root Cause Analysis

### Issue Location:
The batch numbers are resolved and stored in `TaraWeightManager._product_classifications` under the `lote` key, but when product data is fetched for template preview (`templates.py:235`), it looks for `product.get('batch_number')`.

### The Problem:
In `templates.py:api_product_data()`, the product data comes from `smart_label.get_product_data(product_id)`, which returns data from the **products_master** table/CSV. This table does **NOT** contain batch_number data - batch data is stored separately in `product_classifications`.

The batch resolution happens in `labels.py:get_batch_and_tare()` which properly queries `TaraWeightManager`, but this function is **NOT called** in the template preview endpoint.

### Why It Worked Before:
Previously, product data might have been enriched with batch_number before being passed to templates, OR the template preview relied on the queue-add flow which does call `get_batch_and_tare()`.

## Solution

### Option 1: Enrich Template Product Data with Batch Info (RECOMMENDED)
Modify `templates.py:api_product_data()` to call `get_batch_and_tare()` and merge the batch data into the product response:

```python
# In templates.py:api_product_data(), around line 235:
from routes.labels import get_batch_and_tare

# After getting product data, enrich with batch info
tara, lote, fecha, vencimiento = get_batch_and_tare(product_id, product.get('quantity', 0))
batch_number = lote or str(product.get('batch_number', '000000'))
```

### Option 2: Fix in SmartLabelManager
Modify `smart_label.get_product_data()` to also fetch batch data from TaraWeightManager (broader impact).

### Option 3: Frontend Fix
Make the template designer explicitly call the queue-add endpoint first to get batch data, then use that for preview (more complex).

## Additional Notes

### SQL Server Tables:
- `product_batches` table may or may not exist (could not verify due to missing ODBC driver)
- `product_classifications` table is the primary source for batch data
- The `run_sync.py` script syncs batch data from SAP → product_classifications

### Sync Process:
- `/control/sync-sap-batches` endpoint in `control_interno.py` fills missing batches from SAP
- Sync respects user overrides (higher priority)
- Max 1200-5000 items per sync run

## Files Involved:
- `sga_web/routes/templates.py` (lines 154-260) ← **Fix needed here**
- `sga_web/routes/labels.py` (lines 111-148) ← `get_batch_and_tare()` function
- `sga_web/core/tara_weight_manager.py` (lines 2222-2229) ← `get_classification()`
- `sga_web/core/sap_connector.py` (lines 787-886) ← `get_all_latest_batches()`
- `sga_web/routes/control_interno.py` (lines 640-740) ← batch sync logic
