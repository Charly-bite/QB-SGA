import json


def extract():
    with open(
        r"c:\Users\QB_DESARROLLO\Desktop\SGA_dev\scripts\audit_report.txt",
        "r",
        encoding="utf-8",
    ) as f:
        lines = f.readlines()

    in_section = False
    products = []
    current = None

    for line in lines:
        l = line.strip()
        if "SECTION 1:" in l:
            in_section = True
            continue
        if "SECTION 2:" in l:
            break
        if not in_section:
            continue

        if l.startswith("PRODUCT: "):
            if current:
                products.append(current)
            current = {
                "name": l.replace("PRODUCT: ", "").strip(),
                "code": "",
                "hds": "",
                "issues": [],
            }
        elif current and l.startswith("Code:"):
            current["code"] = l.replace("Code:", "").strip()
        elif current and l.startswith("HDS File:"):
            hds_path = l.replace("HDS File:", "").strip()
            current["hds"] = hds_path.split("\\")[-1] if hds_path else "N/A"
        elif current and l.startswith("→ "):
            current["issues"].append(l)

    if current:
        products.append(current)

    with open("preview_clean.txt", "w", encoding="utf-8") as out:
        for i, p in enumerate(products, 1):
            out.write(f"{i}. **{p['name']}** [{p['code']}]\n")
            out.write(f"   HDS: {p['hds']}\n")
            for iss in p["issues"]:
                out.write(f"   - {iss}\n")
            out.write("\n")


if __name__ == "__main__":
    extract()
