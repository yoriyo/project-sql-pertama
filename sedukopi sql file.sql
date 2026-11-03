-- Ranking revenue per gerai
select 
	o.name,
	o.city,
	sum(os.total_amount) as total_spend,
	o.seating_capacity as jumlah_tempat_duduk,
	o.status,
	rank() over (order by sum(os.total_amount) desc) as ranking
from outlets o 
left join orders os on os.outlet_id = o.outlet_id
where o.status = 'active'
group by o.name, o.city, o.seating_capacity, o.status
order by ranking

-- Menu terlaris per kategori
select 
	m.category,
	m.name,
	sum(od.quantity) as total_terjual,
	rank() over (order by sum(od.quantity) desc) as ranking
from menu_items m
join order_details od on m.item_id = od.item_id
where od.quantity is not null
group by m.category, m.name
order by total_terjual desc
limit 5

-- Kontribusi persen Coffee vs Makanan
with per_kategori as (
	select
		m.category,
		sum(od.quantity) as total_per_kategori
	from menu_items m
	join order_details od on m.item_id = od.item_id
	group by m.category
)
SELECT 
    category,
    total_per_kategori,
    ROUND((total_per_kategori / SUM(total_per_kategori) OVER ()) * 100, 2) AS kontribusi_persen
FROM per_kategori
ORDER BY total_per_kategori DESC;

-- Jam ramai pagi vs sore
SELECT 
	ot.city as kota,
    CASE 
        WHEN od.order_time::time BETWEEN '07:00:00' AND '11:00:00' THEN 'Pagi'
        WHEN od.order_time::time BETWEEN '15:00:00' AND '18:00:00' THEN 'Sore'
        ELSE 'Lainnya'
    END AS shift_waktu,
    COUNT(od.order_id) AS total_order
FROM orders od
join outlets ot on od.outlet_id = ot.outlet_id
WHERE 
    od.order_time::time BETWEEN '07:00:00' AND '11:00:00'
    OR od.order_time::time BETWEEN '15:00:00' AND '18:00:00'
GROUP BY shift_waktu, kota;

select *
from orders
where order_date like '2025%'

-- Tren revenue bulanan 2022 vs 2025 (belum fokus karena masuk discord)
WITH monthly_revenue AS (
    SELECT 
        -- 1. Penanda awal bulan untuk sumbu visualisasi (Line Chart)
        DATE_TRUNC('month', o.order_date::date)::date AS order_month,
        
        -- 2. Komponen tahun & bulan untuk analisis musiman & YoY
        EXTRACT(YEAR FROM o.order_date::date) AS tahun,
        EXTRACT(MONTH FROM o.order_date::date) AS nomor_bulan,
        TO_CHAR(o.order_date::date, 'FMMonth') AS nama_bulan,
        
        -- 3. Agregasi total revenue per bulan
        SUM(od.subtotal) AS total_revenue,
        COUNT(o.order_id) AS total_transaksi
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY 
        DATE_TRUNC('month', o.order_date::date)::date,
        EXTRACT(YEAR FROM o.order_date::date),
        EXTRACT(MONTH FROM o.order_date::date),
        TO_CHAR(o.order_date::date, 'FMMonth')
)
SELECT * 
FROM monthly_revenue
ORDER BY order_month ASC;