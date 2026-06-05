# PostgreSQL History Table Boilerplate Demo

This example demonstrates the common boilerplate required to manually implement a history/audit table in PostgreSQL. It creates a sample `products` table, a corresponding `products_history` table, and triggers to log all INSERT, UPDATE, and DELETE operations. The inline comments highlight the repetitive code that a custom PostgreSQL plugin aims to eliminate by automating history tracking.

## Language

`sql`

## How to Run

1. Ensure you have a PostgreSQL server running.
2. Connect to your PostgreSQL database using `psql` or a similar client.
3. Execute the SQL script: `psql -f history_plugin_demo.sql your_database_name`

## Original Article

This example accompanies the Turkish article: [PostgreSQL'de Tarihçe Tablosu Boilerplate Yorgunluğu: Özel Bir Eklentiyle Tanışın](https://fatihsoysal.com/blog/postgresqlde-tarihce-tablosu-boilerplate-yorgunlugu-ozel-bir-eklentiyle-tanisin/).

## License

MIT — see [LICENSE](LICENSE).
