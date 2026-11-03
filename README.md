# project-sql-pertama
Pada repository ini saya membagikan pengalaman pertama saya melakukan dummy project menggunakan PostgreSQL menggunakan dataset yang saya dapatkan di ngulikdata.com

Hai. Selamat datang pada penjelasan portfolio dari dataset yang saya dapatkan melalui website [ngulikdata.com](http://ngulikdata.com). 

Dataset ini saya namakan ‘Sedukopi’ yang memuat 5 tabel di dalamnya. Sedukopi merupakan toko gerai kopi fiktif di beberapa kota terkenal di Indonesia yang sengaja dibuat untuk membantu kami pembelajar SQL atau Spreadsheet dalam mendapatkan project pertama portofolio sebagai Data Analyst. Di dalamnya terdapat lima tabel, yaitu tabel orders, outlets, menu_items, staff, dan order_details.

Melalui kelima tabel tersebut, [ngulikdata.com](http://ngulikdata.com) berharap para pembelajar dapat berlatih lebih maksimal dalam menggunakan konsep JOIN, CTE, Windows Function, dan berbagai hal dalam pengolahan data menggunakan SQL maupun Spreadsheet. Dalam kasus ini, saya menggunakan SQL untuk melakukan analisis data yang kemudian saya bandingkan secara visual menggunakan software bernama Power BI. 

## 1. Ide Analisis

Ide analisis tiga pertama merupakan ide yang diberikan oleh [ngulikdata.com](http://ngulikdata.com). Proses yang saya lakukan pertama kali adalah memastikan kolom pertama yang berfungsi sebagai judul kolom sudah tepat dan data yang diberikan sudah sesuai menggunakan Python.

```python
import pandas as pd

df = pd.read_csv('outlets.csv') # <--- Kode pertama yang saya gunakan untuk ekstrak file csv

df.head() # <--- Kode yang digunakan untuk melihat 5 baris pertama termasuk judul kolom

df.info() # <--- Kode yang digunakan untuk melihat seluruh tipe data dari semua kolom

df.isnull().sum() # <--- Kode untuk menghitung berapa jumlah data Null sepanjang kolom

# Importing ke PostgreSQL
username = "*******"
password = "********"
host = "******"
port = "****"
database = "*******"

# Import SQLAlchemy
from sqlalchemy import create_engine

engine = create_engine(f"postgresql+psycopg2://{username}:{password}@{host}:{port}/{database}")

# Load DataFrame into PostgreSQL
table_name = "******"
df.to_sql(table_name, engine, if_exists="replace", index=False)

print(f"Data Successfully loaded into table '{table_name}' in database '{database}'.")

# Inilah kemudian kode lengkap saya untuk melakukan import dari Python ke PostgreSQL
# yang dimana berisikan *** tersebut dapat anda isi dengan data yang anda miliki di PostgreSQL.
```

Setelah dilakukan pemeriksaan terhadap data yang digunakan serta dilakukan pemindahan dari Python ke dalam database PostgreSQL saya dapat melanjutkan untuk melakukan analisis terhadap tiga ide analisis yang diberikan [ngulikdata.com](http://ngulikdata.com). Berikut adalah 3 ide analisis pertama yang melatih saya bagaimana menggunakan fungsi agregasi dan fungsi JOIN: 

1. Ranking Revenue per Goal
Pertanyaan bisnis: “*Head of Operations* Sedukopi ingin mengetahui gerai mana yang paling banyak nyetak revenue dan mana yang paling merugi dari 20 gerai yang dimiliki.
2. Menu Terlaris per Kategori
Pertanyaan bisnis: Tim menu ingin mengetahui mana menu terlaris dari setiap gerai di tiap kota untuk dilakukan pemaksimalan pasokan bahan baku. Dan tim menu juga ingin mengetahui top 5 menu dari tiap kategori serta kontribusi kategori Coffee vs Makanan terhadap total unit terjual.
3. Jam Ramai
Pertanyaan bisnis: Head manager gerai ingin mengetahui bagaimana jumlah pesanan tiap waktunya, pagi, siang, dan sore di seluruh gerai di tiap kota untuk mengatur jadwal barista guna efisiensi pengeluaran pemilik gerai.

## 2. Menjawab 3 Pertanyaan Bisnis

Dalam bagian ini, saya akan menampilkan secara langsung dan lengkap query yang saya gunakan untuk menjawab tiga pertanyaan bisnis tersebut

1. Ranking Revenue per Goal

```sql
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
```

1. Menu Terlaris per Kategori

- Top 5 per kategori

- Perbandingan Coffee vs Makanan

```sql
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
```

```sql
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
```

1. Jam Ramai 

```sql
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
```
