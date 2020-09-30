import { MigrationInterface, QueryRunner } from "typeorm";

export class SetupFullTextSearch1552096655610 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<any> {
    await queryRunner.query(`
    update card set document_with_weights = setweight(to_tsvector(name), 'A') ||
  setweight(to_tsvector(artist), 'B') ||
    setweight(to_tsvector(coalesce(text, '')), 'C');

CREATE INDEX document_weights_idx
  ON card
  USING GIN (document_with_weights);

        CREATE FUNCTION card_tsvector_trigger() RETURNS trigger AS $$
begin
  new.document_with_weights :=
  setweight(to_tsvector('english', coalesce(new.name, '')), 'A')
  || setweight(to_tsvector('english', coalesce(new.artist, '')), 'B')
  || setweight(to_tsvector('english', coalesce(new.text, '')), 'C');
  return new;
end
$$ LANGUAGE plpgsql;

CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
    ON card FOR EACH ROW EXECUTE PROCEDURE card_tsvector_trigger();
        `);
  }

  public async down(): Promise<any> {}
}
