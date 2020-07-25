/*Creating Tables with the provided queries in a Wave Database*/
CREATE TABLE users (
u_id integer PRIMARY KEY,
name text NOT NULL,mobile text NOT NULL,
wallet_id integer NOT NULL,
when_created timestamp without time zone NOT NULL
-- more stuff :)
);

CREATE TABLE transfers (
transfer_id integer PRIMARY KEY,
u_id integer NOT NULL,
source_wallet_id integer NOT NULL,
dest_wallet_id integer NOT NULL,send_amount_currency text NOT NULL,
send_amount_scalar numeric NOT NULL,
receive_amount_currency text NOT NULL,
receive_amount_scalar numeric NOT NULL,
kind text NOT NULL,dest_mobile text,
dest_merchant_id integer,
when_created timestamp without time zone NOT NULL
-- more stuff :)
);

CREATE TABLE agents (
agent_id integer PRIMARY KEY,
name text,country text NOT NULL,
region text,city text,
subcity text,
when_created timestamp without time zone NOT NULL
-- more stuff :)
);

CREATE TABLE agent_transactions (
atx_id integer PRIMARY KEY,
u_id integer NOT NULL,
agent_id integer NOT NULL,
amount numeric NOT NULL,
fee_amount_scalar numeric NOT NULL,
when_created timestamp without time zone NOT NULL
-- more stuff :)
);

CREATE TABLE wallets (
wallet_id integer PRIMARY KEY,
currency text NOT NULL,
ledger_location text NOT NULL,
when_created timestamp without time zone NOT NULL
-- more stuff :)
);

		/*QUESTION ONE(1)
Finding the number of user Wave has*/
SELECT DISTINCT COUNT (*) from users;


		/*QUESTION TWO(2)
Finding the number of transfers that have been sent in the currency "CFA"*/

SELECT COUNT (*) from transfers 
	WHERE  send_amount_currency = 'CFA';
	
	
		/*QUESTION THREE(3)
Finding the number of different users that have sent a transfer in "CFA"*/

SELECT DISTINCT COUNT (u_id)
	FROM transfers 
	WHERE send_amount_currency = 'CFA';  


		/*QUESTION FOUR(4)
Finding the number of agent_transactions made in 2018 and grouping them by Months*/

SELECT TO_CHAR(when_created, 'Month') AS "Month",
	COUNT (atx_id) 
	FROM agent_transactions
	WHERE   when_created >= '2018-01-01 00:00:00' 
	AND     when_created <= '2018-12-31 23:59:59'
	GROUP BY "Month";


		/*QUESTION FIVE(5)
Finding the number of Wave agents who were “netdepositors” vs. “netwithdrawers”
over the course of last week*/

SELECT SUM(case when amount > 0 THEN amount else 0 END) AS withdrawal,
SUM( case when amount < 0 then amount else 0 END) AS deposit,
CASE WHEN ((sum(case when amount > 0 THEN amount else 0 END)) > 
		   ((sum(case when amount < 0 then amount else 0 END))) * -1)
then 'withdrawer'
else 'depositer' END AS agent_status,
COUNT(*) FROM agent_transactions
WHERE agent_transactions.when_created between (now() - '1 WEEK'::INTERVAL) and now();	
	
	
		/*QUESTION SIX(6)	
Build an “atx volume city summary” table: 
find the volume of agent transactions createdin the last week, 
grouped by city. You can determine the city where the agent transaction took 
place from the agent’s city field*/

select agents.city, count(amount)
from agent_transactions
inner join agents on agents.agent_id = agent_transactions.agent_id
Where agent_transactions.when_created > current_date - interval '7 days'
GROUP BY agents.city;


		/*QUESTION SEVEN(7)
Separating the atx volume by country with columns: country,city and volume*/

SELECT count(atx.atx_id) AS "Atx Volume",count(ag.city) AS "City",
count(ag.country) AS "Country"
FROM agent_transactions AS Atx 
INNER JOIN agents AS Ag ON atx.atx_id = ag.agent_id
GROUP BY ag.country;


		/*QUESTION EIGHT(8)
Building a “send volume by country and kind” table: 
finding the total volume of transfers (bysend_amount_scalar) sent in the past week, 
grouped by country and transfer kind.*/

SELECT transfers.kind AS Transfer_Kind,
wallets.ledger_location AS Country,
SUM(transfers.send_amount_scalar) AS Volume
FROM transfers
INNER JOIN wallets ON transfers.source_wallet_id = wallets.wallet_id
WHERE (transfers.when_created > (NOW() - INTERVAL '1 week'))
GROUP BY Country, Transfer_Kind;


		/*QUESTION NINE(9)
Adding columns for transaction count and number of unique senders 
to the “send volume by country and kind” table
and grouped by country and transfer kind.*/

SELECT COUNT(transfers.source_wallet_id) AS Unique_Senders,
COUNT (transfer_id) AS Atx_Count,
transfers.kind AS Transfer_Kind,
wallets.ledger_location AS Country,
SUM (transfers.send_amount_scalar) AS Volume
FROM transfers
INNER JOIN wallets
ON transfers.source_wallet_id = wallets.wallet_id
WHERE (transfers.when_created > (NOW() - INTERVAL '1 week'))
GROUP BY Country, Transfer_Kind;




		/*QUESTION TEN(10)
Identifying wallets that have sent more than 10,000,000 CFA in transfers 
in the last month(as identified by the source_wallet_id column on the transfers table),
and how much they send*/

SELECT  w.wallet_id,tn.source_wallet_id,tn.send_amount_scalar
FROM transfers AS tn 
INNER JOIN wallets AS w ON tn.transfer_id = w.wallet_id
WHERE tn.send_amount_scalar > 10000000 
AND (tn.send_amount_currency = 'CFA' AND tn.when_created > CURRENT_DATE-INTERVAL '1 month')