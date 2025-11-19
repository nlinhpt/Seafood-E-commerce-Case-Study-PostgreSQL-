# Seafood-E-commerce-Case-Study-PostgreSQL
Objective
--------
- Analyze user behavior on a seafood e‑commerce site to measure the conversion funnel (view → add-to-cart → purchase), detect abandoned carts, and surface top/bottleneck products and categories.

About data
----------
- ERD: `assets/ERD-Seafood-Project.png`  
- Main tables:
  - `page_hierarchy`: 9 product pages (Salmon, Kingfish, Tuna, Russian Caviar, Black Truffle, Abalone, Lobster, Crab, Oyster) with `product_id` and `category` (Fish, Luxury, Shellfish).
  - `users`: visitors tracked by `cookie_id`.
  - `event_identifier`: lookup for event types (Page View, Add to Cart, Purchase, Ad Impression, Ad Click).
  - `campaign_identifier`: info about three marketing campaigns.
  - `events`: event-level logs (`cookie_id`, `page_id`, `event_type`, `event_time`, `sequence_number`, ...).

Key insights
------------
- Overall conversion: ~**49.86%** of sessions resulted in a purchase.  
- Funnel efficiency:
  - ~**61%** of views → add-to-cart.
  - ~**76%** of add-to-cart → purchase.
  - ~**15.5%** checkout abandonment rate.
- Highest abandonment: **Russian Caviar** (Luxury) — frequently added to cart but rarely purchased.  
- Highest view→purchase rate: **Lobster** (~**48.74%**).  
- Top sellers (by purchase volume): **Lobster, Oyster, Crab** (all Shellfish).

## Added files
- `data/casestudy_db.sql` — PostgreSQL dump to create and populate the case study database.
- `sql/solution.sql` — SQL solution that answers the analysis questions and builds summary tables (e.g., `product_summary`, `category_summary`).
