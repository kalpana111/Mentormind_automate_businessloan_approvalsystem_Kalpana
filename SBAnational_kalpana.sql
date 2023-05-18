-- Creating table SBAnational and showing the data

drop table public."SBAnational";

create table public."SBAnational"(
	LoanNr_ChkDgt bigint primary key,
	Name varchar(50),
	City varchar(50),
	State varchar(10),
	Zip varchar(6),
	Bank varchar(50),
	BankState varchar(10),
	NAICS int,
	ApprovalDate date,
	ApprovalFY varchar(50),
	Term int,
	NoEmp int,
	NewExist int,
	CreateJob int,
	RetainedJob int,
	FranchiseCode int,
	UrbanRural int,
	RevLineCr varchar(10),
	LowDoc varchar(10),
	ChgOffDate date,
	DisbursementDate date,
	DisbursementGross varchar(50),
	BalanceGross varchar(50),
	MIS_Status varchar(50),
	ChgOffPrinGr varchar(50),
	GrAppv varchar(50),
	SBA_Appv varchar(50)
);

select * from public."SBAnational";



-- Module 4 Solutions:
-- Task 1:

-- Using Window functions, explore the top 3, 5 or 10 customers based on certain metrics (Eg - Find the top 5 customers with highest bank balance who have not defaulted on a loan in the last 2 years). This will help you understand your ideal loan applicants.
DROP VIEW top_customers;

CREATE VIEW top_customers AS (
  SELECT Name ,ApprovalDate,MIS_Status,GrAppv,
    row_number() over(PARTITION BY MIS_Status  ORDER BY GrAppv DESC) AS rowno
  FROM public."SBAnational"
)
-- Top 3 customers
SELECT Name ,ApprovalDate,MIS_Status,GrAppv
FROM top_customers
WHERE ApprovalDate < TO_DATE('2012-01-01', 'YYYY-MM-DD') and MIS_Status='P I F' limit 3;

-- Top 5 customers
SELECT Name ,ApprovalDate,MIS_Status,GrAppv
FROM top_customers
WHERE ApprovalDate < TO_DATE('2012-01-01', 'YYYY-MM-DD') and MIS_Status='P I F' limit 5;

-- Top 10 customers
SELECT Name ,ApprovalDate,MIS_Status,GrAppv
FROM top_customers
WHERE ApprovalDate < TO_DATE('2012-01-01', 'YYYY-MM-DD') and MIS_Status='P I F' limit 10;



-- Task 2:

select * from public."SBAnational";

-- UrbanRural COLUMN ANALYSIS

select UrbanRural,count(*) as urbanRural_count
from public."SBAnational"
where MIS_Status = 'P I F'
group by UrbanRural
order by urbanRural_count desc;
/*
1	354414
0	299848
2	85347
*/

select UrbanRural,count(*) as urbanRural_count
from public."SBAnational"
where MIS_Status = 'CHGOFF'
group by UrbanRural
order by urbanRural_count desc;

/* 
1	114867
0	22978
2	19713 
*/
-- no insight from this column

-- Data Cleaning for further analysis:

-- To remove the $ signs from chgoffpringr column
ALTER TABLE public."SBAnational" ADD COLUMN chgoffpringr_int numeric(12,2);
UPDATE public."SBAnational" SET chgoffpringr_int = CAST(REPLACE(REPLACE(REPLACE(chgoffpringr, '$', ''), ',', ''), ' ', '') AS numeric(12,2));
ALTER TABLE public."SBAnational" DROP COLUMN chgoffpringr;
ALTER TABLE public."SBAnational" RENAME COLUMN chgoffpringr_int TO chgoffpringr;

-- To remove the $ signs from disbursementgross column
ALTER TABLE public."SBAnational" ADD COLUMN disbursementgross_int numeric(12,2);
UPDATE public."SBAnational" SET disbursementgross_int = CAST(REPLACE(REPLACE(REPLACE(disbursementgross, '$', ''), ',', ''), ' ', '') AS numeric(12,2));
ALTER TABLE public."SBAnational" RENAME COLUMN disbursementgross TO disbursementgross_original;
ALTER TABLE public."SBAnational" RENAME COLUMN disbursementgross_int TO disbursementgross;

-- To remove the $ signs from grappv column
ALTER TABLE public."SBAnational" ADD COLUMN grappv_int numeric(12,2);
UPDATE public."SBAnational" SET grappv_int = CAST(REPLACE(REPLACE(REPLACE(grappv, '$', ''), ',', ''), ' ', '') AS numeric(12,2));
ALTER TABLE public."SBAnational" DROP COLUMN grappv;
ALTER TABLE public."SBAnational" RENAME COLUMN grappv_int TO grappv;

-- To remove the $ signs from sba_appv column
ALTER TABLE public."SBAnational" ADD COLUMN sba_appv_int numeric(12,2);
UPDATE public."SBAnational" SET sba_appv_int = CAST(REPLACE(REPLACE(REPLACE(sba_appv, '$', ''), ',', ''), ' ', '') AS numeric(12,2));
ALTER TABLE public."SBAnational" DROP COLUMN sba_appv;
ALTER TABLE public."SBAnational" RENAME COLUMN sba_appv_int TO sba_appv;

-- To remove the $ signs from balancegross column
ALTER TABLE public."SBAnational" ADD COLUMN balancegross_int numeric(12,2);
UPDATE public."SBAnational" SET balancegross_int = CAST(REPLACE(REPLACE(REPLACE(balancegross, '$', ''), ',', ''), ' ', '') AS numeric(12,2));
ALTER TABLE public."SBAnational" DROP COLUMN balancegross;
ALTER TABLE public."SBAnational" RENAME COLUMN balancegross_int TO balancegross;

--We saw that our approvalfy column data type is not int this is because of the value is wrongly enterted as 1976A. We will remove A and coorect the column data type to int by following query
UPDATE public."SBAnational"
SET approvalfy = REPLACE(approvalfy, 'A', '')::integer;


-- Now we will explore information from the data by using DML commands
-- Debt-to-Income Ratio (DTI):
-- DTI is the ratio of a borrower's monthly debt payments to their monthly income. A lower DTI indicates that the borrower has more disposable income available to repay the loan.
SELECT (SUM(ChgOffPrinGr) + SUM(BalanceGross)) / SUM(DisbursementGross) AS DTI
FROM public."SBAnational";

/*Average number of employees (NoEmp) for approved loans:,
This metric holds significance as it allows the bank to assess the borrower's capacity to pay back the loan depending on the size of their organization.
*/
SELECT ROUND(AVG(NoEmp)::numeric, 4) AS avg_num_employees
FROM public."SBAnational"
WHERE MIS_Status = 'P I F';

/*Average loan term (Term) for approved loans:
This metric is important as it can help the bank set loan terms that are suitable for the borrower and minimize the threat of loan dereliction.
*/
SELECT ROUND(AVG(Term), 2) AS avg_loan_term
FROM public."SBAnational"
WHERE MIS_Status = 'P I F';

/*The ratio of charged off principal amount (ChgOffPrinGr) to gross loan amount (GrAppv):
This standard is important as it can help the bank assess the creditworthiness of its borrowers and estimate its loan portfolio threat.
*/
SELECT ROUND(SUM(ChgOffPrinGr)/SUM(GrAppv), 2) AS charge_off_ratio 
from public."SBAnational"; 

/*checking the number of paid and defaults as per urban and rural status 
This metric is essential as this will give a glance of the most number of paid or default are from which sector 
*/
select count(*),mis_status ,urbanrural  
from public."SBAnational"
group by mis_status,urbanrural;

/*We can use more different metrics as per business need to get insights from the data such as 
We can check the name and defaulted or paid loan amounts more than 5000000
*/
select Name,grappv,mis_status from public."SBAnational" where GrAppv >= 5000000;


/*Count of loan (paid and defaulted )application by type of business :
This metric is very important as this will give bank an idea of what the ratio of loan defaulted and paid by new and existing business
*/
SELECT MIS_Status, count(NewExist),
CASE
    WHEN NewExist =2 THEN 'new_business'
    WHEN NewExist = 1 THEN 'existing_business'
    ELSE 'not_defined'
END AS BUSINESS_STATUS
FROM public."SBAnational" group by MIS_Status,BUSINESS_STATUS;

-- Count of loan (paid and defaulted )application by type of UrbanRural :
SELECT MIS_Status, count(UrbanRural),
CASE
    WHEN UrbanRural = 1 THEN 'Urban'
    WHEN UrbanRural = 2 THEN 'rural'
    ELSE 'not_defined'
END AS RESIDENTIAL_STATUS
FROM public."SBAnational" group by MIS_Status,RESIDENTIAL_STATUS;

-- Count of loan (paid and defaulted )application by type of LowDoc :
SELECT MIS_Status, count(LowDoc),
CASE
    WHEN LowDoc = 'Y' THEN 'Yes'
    WHEN LowDoc = 'N' THEN 'No'
    ELSE 'not_defined'
END AS DOCUMENT_STATUS
FROM public."SBAnational" group by MIS_Status,DOCUMENT_STATUS;


-- Now we will try to check the loans status by using different metrics we can differ the metrics according to the need of the bank and we can play along different metrics
SELECT 
    LoanNr_ChkDgt,MIS_Status,GrAppv,term,NoEmp,DisbursementGross,ChgOffPrinGr,
    CASE
        WHEN GrAppv >= 50000 AND GrAppv <= 250000 AND Term <= 84 AND NoEmp <= 100 
		AND DisbursementGross <= 250000 AND ChgOffPrinGr <= 10000 THEN 'Approved'
        WHEN GrAppv >= 250000 AND GrAppv <= 500000 AND Term <= 120 AND NoEmp<= 250 
		AND DisbursementGross<= 500000 AND ChgOffPrinGr <= 50000 THEN 'Approved'
        ELSE 'Declined'
    END AS Loan_Status
FROM public."SBAnational";

/*
This query selects several columns from the public."SBAnational" table and uses a CASE statement to assign a loan status to each row based on certain criteria. The criteria for "Approved" loans are:

"GrAppv" (the approved loan amount) is between $50,000 and $250,000
"Term" (the loan term in months) is less than or equal to 84
"NoEmp" (the number of employees) is less than or equal to 100
"DisbursementGross" (the total amount disbursed) is less than or equal to $250,000
"ChgOffPrinGr" (the charged-off principal amount) is less than or equal to $10,000

The criteria for "Approved" loans with higher amounts are:

"GrAppv" is between $250,000 and $500,000
"Term" is less than or equal to 120
"NoEmp" is less than or equal to 250
"DisbursementGross" is less than or equal to $500,000
"ChgOffPrinGr" is less than or equal to $50,000
All other loans are assigned a status of "Declined".

The thresholds for these criteria and loan statuses were likely chosen based on industry standards, risk assessment, and the loan approval policies. The specific thresholds chosen may vary depending on the specific context and goals of the analysis.
*/

-- Write out your final query that creates a column in the table (Refer to the commands in C3) which says whether a customer is eligible for a loan or not based on the criterion you set in the previous component.

SELECT Name, MIS_Status,
  CASE
      WHEN MIS_Status ='CHGOFF' THEN 'Not eligible for loan'
      WHEN MIS_Status = 'P I F' THEN 'Eligible for loan'
      ELSE 'Not defined'
  END AS Loan_Eligibility
FROM public."SBAnational"
LIMIT 1000;

CREATE VIEW final_query as (
SELECT 
    Name,LoanNr_ChkDgt,MIS_Status,GrAppv,term,NoEmp,DisbursementGross,ChgOffPrinGr,
    CASE
        WHEN GrAppv >= 50000 AND GrAppv <= 250000 AND Term <= 84 AND NoEmp <= 100 
		AND DisbursementGross <= 250000 AND ChgOffPrinGr <= 10000 AND MIS_Status = 'P I F' THEN 'Approved'
        WHEN GrAppv >= 250000 AND GrAppv <= 500000 AND Term <= 120 AND NoEmp<= 250 
		AND DisbursementGross<= 500000 AND ChgOffPrinGr <= 50000 AND MIS_Status = 'P I F' THEN 'Approved'
        ELSE 'Declined'
    END AS Loan_Status
FROM public."SBAnational"
)

SELECT Name,
  CASE
      WHEN Loan_Status ='Declined' THEN 'Not eligible for loan'
      WHEN Loan_Status = 'Approved' THEN 'Eligible for loan'
      ELSE 'Not defined'
  END AS Loan_Eligibility
FROM final_query
;


































