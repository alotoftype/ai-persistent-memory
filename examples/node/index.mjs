import pg from 'pg';

const databaseUrl = process.env.DATABASE_URL || 'postgresql://memory_admin:change_me@127.0.0.1:5432/memory';
const { Client } = pg;

const client = new Client({ connectionString: databaseUrl });

await client.connect();

const insert = await client.query(
  `insert into memory.memories
    (source, kind, title, summary, content, tags, entities, importance, metadata)
   values
    ($1, $2, $3, $4, $5, $6, $7, $8, $9)
   returning id, title, created_at`,
  [
    'node-example',
    'fact',
    'Favorite coffee',
    'Preference captured from chat',
    'Serge likes strong coffee in the morning.',
    ['preference', 'coffee'],
    ['Serge'],
    4,
    { channel: 'example', capturedBy: 'node-client' }
  ]
);

console.log('Inserted:', insert.rows[0]);

const recent = await client.query(
  `select id, title, kind, importance, created_at
   from memory.memories
   where tags && $1::text[]
   order by created_at desc
   limit 5`,
  [['coffee']]
);

console.log('Recent coffee memories:');
for (const row of recent.rows) {
  console.log(row);
}

await client.end();
