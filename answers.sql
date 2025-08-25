/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
SELECT market FROM dim_customer WHERE customer= "Atliq Exclusive" AND region = "APAC";

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */
SELECT cte1.unique_products_2020 , cte2.unique_products_2021 ,(( cte2.unique_products_2021-cte1.unique_products_2020)*100)/cte1.unique_products_2020 AS percentage_chg FROM 
((SELECT COUNT(DISTINCT (product_code)) as unique_products_2020 FROM fact_sales_monthly WHERE fiscal_year = 2020) cte1,
(SELECT COUNT(DISTINCT (product_code)) as unique_products_2021 FROM fact_sales_monthly WHERE fiscal_year = 2021) cte2);

/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/
SELECT segment, COUNT(DISTINCT(product_code)) AS product_count FROM dim_product GROUP BY segment ORDER BY product_count DESC;

/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/
WITH cte1 AS (SELECT segment, COUNT(DISTINCT(s.product_code)) AS product_count_2020 FROM dim_product p JOIN fact_sales_monthly s ON p.product_code = s.product_code
WHERE s.fiscal_year = 2020 GROUP BY segment),
cte2 AS (SELECT segment, COUNT(DISTINCT(s.product_code)) AS product_count_2021 FROM dim_product p JOIN fact_sales_monthly s ON p.product_code = s.product_code
WHERE s.fiscal_year = 2021 GROUP BY segment)
SELECT cte1.segment, cte1.product_count_2020, cte2.product_count_2021, cte2.product_count_2021 - cte1.product_count_2020 AS difference
FROM cte1 JOIN cte2 ON cte1.segment = cte2.segment ORDER BY difference DESC;

/* 5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost*/
WITH cte1 AS (SELECT m.product_code, p.product, m.manufacturing_cost FROM fact_manufacturing_cost m JOIN dim_product p ON m.product_code = p.product_code WHERE
 manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)),
 cte2 AS (SELECT m.product_code, p.product, m.manufacturing_cost FROM fact_manufacturing_cost m JOIN dim_product p ON m.product_code = p.product_code WHERE
 manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost))
 
 SELECT * FROM cte1 union SELECT * FROM cte2;
 
 /*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */
WITH cte1 AS (
SELECT customer_code, AVG(pre_invoice_discount_pct) AS average_discount_percentage FROM fact_pre_invoice_deductions WHERE fiscal_year = 2021
GROUP BY customer_code ORDER BY average_discount_percentage )
SELECT cte1.customer_code, cte1.average_discount_percentage, customer FROM cte1 LEFT JOIN dim_customer c 
ON cte1.customer_code = c.customer_code WHERE market = "India" ORDER BY average_discount_percentage desc LIMIT 5 ;


/*7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/
WITH cte1 AS (SELECT MONTHNAME(date) AS Month, YEAR(date) as Year, (gross_price*sold_quantity) as Gross_sales_Amount FROM fact_gross_price g JOIN fact_sales_monthly s ON
g.product_code = s.product_code JOIN dim_customer c ON c.customer_code = s.customer_code
WHERE customer = 'Atliq Exclusive')
SELECT cte1.Month, cte1.Year, ROUND(SUM(cte1.Gross_sales_Amount),2) AS Gross_sales_Amount FROM cte1 GROUP BY cte1.Month, cte1.year;

/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity*/

SELECT CASE
 WHEN MONTH(date_add(date,interval 4 month))/3 <= 1 THEN "Q1"
   WHEN MONTH(date_add(date,interval 4 month))/3 <= 2 and MONTH(date_add(date,interval 4 month))/3 > 1 THEN "Q2"
   WHEN MONTH(date_add(date,interval 4 month))/3 <=3 and MONTH(date_add(date,interval 4 month))/3 > 2 THEN "Q3"
   WHEN MONTH(date_add(date,interval 4 month))/3 <=4 and MONTH(date_add(date,interval 4 month))/3 > 3 THEN "Q4" END Quarter,
SUM(sold_quantity) AS total_sold_quantity FROM fact_sales_monthly WHERE fiscal_year = 2020 GROUP BY Quarter ORDER BY total_sold_quantity DESC;

/* 9.Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */
WITH cte1 AS (SELECT s.product_code ,customer_code, ROUND(SUM(sold_quantity * gross_price)/1000000,2) AS gross_sales_mln FROM fact_gross_price g JOIN fact_sales_monthly s 
ON g.product_code = s.product_code WHERE s.fiscal_year =2021 GROUP BY customer_code)
SELECT channel, SUM(cte1.gross_sales_mln) AS gross_sales_mln , ROUND(SUM(cte1.gross_sales_mln)/(SUM(SUM(cte1.gross_sales_mln)) OVER())*100,2) AS percentage
FROM cte1 JOIN dim_customer c ON cte1.customer_code = c.customer_code GROUP BY channel;

/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,division
product_code
product
total_sold_quantity
rank_order*/
/*division,product from dim_product, product_code, sold_quantity from */

WITH cte1 AS (SELECT division, product, s.product_code, SUM(sold_quantity) AS total_sold_quantity FROM dim_product p JOIN fact_sales_monthly s
ON p.product_code = s.product_code WHERE s.fiscal_year = 2021 GROUP BY product_code),

cte2 AS (SELECT cte1.division, cte1.product, cte1.product_code, cte1.total_sold_quantity , dense_rank() over(partition by cte1.division order by total_sold_quantity desc ) AS rank_order
FROM cte1)
SELECT * from cte2 HAVING rank_order < 4
 ;
