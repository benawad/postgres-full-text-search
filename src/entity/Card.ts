import { Column, Entity, PrimaryColumn } from "typeorm";

@Entity()
export class Card {
  @PrimaryColumn()
  index: number;

  @Column()
  name: number;

  @Column()
  artist: string;

  @Column()
  text: string;

  @Column("tsvector", { select: false })
  document_with_weights: any;
}
