DROP EXTERNAL TABLE IF EXISTS team_44_customers_external;

CREATE EXTERNAL TABLE team_44_customers_external (
Customer_Index integer,
Customer_Id varchar(64),
First_Name text,
Last_Name text,
Company text,
City varchar(128),
Country varchar(128),
Phone_1 varchar(64),
Phone_2 varchar(64),
Email text,
Subscription_Date date,
Website text) 
LOCATION('gpfdist://localhost:2308/customers.csv')
FORMAT 'CSV' (DELIMITER ',' HEADER);

select * from team_44_customers_external;