from pyspark.sql import SparkSession
from pyspark.sql import functions

session = SparkSession.builder \
    .master("yarn") \
    .appName("spark-with-yarn") \
    .config("spark.sql.warehouse.dir", "/user/hive/warehouse") \
    .config("spark.hadoop.hive.metastore.uris", "thrift://192.168.1.178:9083") \
    .enableHiveSupport() \
    .getOrCreate()

df = session.read.csv("/input/customers-100000.csv", header=True, inferSchema=True)

res_df = df.groupBy("Country").agg(
    functions.min("Index"),
    functions.max("Index"),
    functions.sum("Index"),
    functions.count("Customer Id"),
    functions.max("Subscription Date"),
    functions.min("Subscription Date")
).sort("Country")

res_df.show()
res_df.write.save("/input/customers_res.csv", format="csv")
res_df.write.saveAsTable("customers_res")
