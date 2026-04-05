## Question
The `schools` table has a full-text search index on `name` and `town`. Why do we need a special index instead of just using `WHERE name = 'something'`?

## Answer
"I don't know"

## Full Explanation
`WHERE name = 'something'` is an exact match. The user would have to type the school name perfectly:
- `"Government Bilingual High School Buea"` ✅ finds it
- `"Bilingual High School"` ❌ finds nothing
- `"buea school"` ❌ finds nothing

That's terrible UX for a school search feature.

**Full-text search** understands natural language queries. It breaks text into individual words and indexes them:
- `"buea"` → finds all schools in Buea
- `"bilingual"` → finds all bilingual schools
- `"high school buea"` → finds schools matching any of those words

**Why a GIN index specifically?**

Without an index, PostgreSQL does a full table scan — reads every row and checks it. With 10,000 schools that's slow.

A GIN (Generalized Inverted Index) pre-builds a map of every word to every row containing it. Like the index at the back of a book — instead of reading every page to find "Buea", you jump straight to the page numbers.

```sql
-- Create the index
CREATE INDEX schools_search_idx ON schools 
USING GIN (to_tsvector('english', name || ' ' || town));

-- Use it in a query
WHERE to_tsvector('english', name || ' ' || town) 
    @@ plainto_tsquery('english', 'buea high school')
```

`||` means concatenate (join strings together). So `name || ' ' || town` combines the school name and town into one searchable string.
