select name, artist, text
from card
where to_tsvector(name) @@ to_tsquery('Wall');

select name, artist, text
from card
where to_tsvector(name || ' ' || text) @@ to_tsquery('Wall');

select name, artist, text
from card
where to_tsvector(name || ' ' || artist || ' ' || text) @@ to_tsquery('Avon');

ALTER TABLE card
  ADD COLUMN document tsvector;
update card
set document = to_tsvector(name || ' ' || artist || ' ' || text);

select name, artist, text
from card
where document @@ to_tsquery('Avon');

explain analyze select name, artist, text
                from card
                where to_tsvector(name || ' ' || artist || ' ' || text) @@ to_tsquery('Avon');
explain analyze select name, artist, text
                from card
                where document @@ to_tsquery('Avon');

ALTER TABLE card
  ADD COLUMN document_with_idx tsvector;
update card
set document_with_idx = to_tsvector(name || ' ' || artist || ' ' || coalesce(text, ''));
CREATE INDEX document_idx
  ON card
  USING GIN (document_with_idx);

explain analyze select name, artist, text
                from card
                where document @@ to_tsquery('Avon');
explain analyze select name, artist, text
                from card
                where document_with_idx @@ to_tsquery('Avon');

select name, artist, text
from card
where document_with_idx @@ plainto_tsquery('island')
order by ts_rank(document_with_idx, plainto_tsquery('island'));


ALTER TABLE card
  ADD COLUMN document_with_weights tsvector;
update card
set document_with_weights = setweight(to_tsvector(name), 'A') ||
  setweight(to_tsvector(artist), 'B') ||
    setweight(to_tsvector(coalesce(text, '')), 'C');
CREATE INDEX document_weights_idx
  ON card
  USING GIN (document_with_weights);

select name, artist, text
from card
where document_with_weights @@ plainto_tsquery('island')
order by ts_rank(document_with_weights, plainto_tsquery('island')) desc;

select name, artist, text, ts_rank(document_with_weights, plainto_tsquery('island'))
from card
where document_with_weights @@ plainto_tsquery('island')
order by ts_rank(document_with_weights, plainto_tsquery('island')) desc;

CREATE FUNCTION card_tsvector_trigger() RETURNS trigger AS $$
begin
  new.document :=
  setweight(to_tsvector('english', coalesce(new.name, '')), 'A')
  || setweight(to_tsvector('english', coalesce(new.artist, '')), 'B')
  || setweight(to_tsvector('english', coalesce(new.text, '')), 'C');
  return new;
end
$$ LANGUAGE plpgsql;

CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
    ON card FOR EACH ROW EXECUTE PROCEDURE card_tsvector_trigger();