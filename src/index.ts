import "reflect-metadata";
import { createConnection } from "typeorm";
import { Card } from "./entity/Card";

createConnection()
  .then(async connection => {
    const data = await connection
      .createQueryBuilder(Card, "c")
      .select()
      .where("document_with_weights @@ plainto_tsquery(:query)", {
        query: "island"
      })
      .orderBy(
        "ts_rank(document_with_weights, plainto_tsquery(:query))",
        "DESC"
      )
      .getMany();
    console.log(data);
  })
  .catch(error => console.log(error));
