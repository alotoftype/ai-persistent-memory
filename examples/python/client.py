import os
import psycopg

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://memory_admin:change_me@127.0.0.1:5432/memory",
)

with psycopg.connect(DATABASE_URL) as conn:
    with conn.cursor() as cur:
        cur.execute(
            """
            insert into memory.memories
              (source, kind, title, summary, content, tags, entities, importance, metadata)
            values
              (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            returning id, title, created_at
            """,
            (
                "python-example",
                "task",
                "Follow up on budget",
                "Reminder captured from a conversation",
                "Serge wants a practical budget follow-up next week.",
                ["budget", "follow-up"],
                ["Serge"],
                5,
                {"channel": "example", "captured_by": "python-client"},
            ),
        )
        inserted = cur.fetchone()
        print("Inserted:", inserted)

        cur.execute(
            """
            select id, title, kind, importance, created_at
            from memory.memories
            where importance >= %s
            order by created_at desc
            limit 5
            """,
            (4,),
        )
        print("Important memories:")
        for row in cur.fetchall():
            print(row)
