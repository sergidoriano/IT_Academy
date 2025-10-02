-- NIVELL 1

-- EXERCICI 1

-- EXERCICI 2:
-- 2.1 Llistat dels països que estan generant vendes.

USE transactions;
SELECT DISTINCT company.country
FROM company
JOIN transaction 
    ON company.id = transaction.company_id;

-- 2.2 Des de quants països es generen les vendes.
USE transactions;
SELECT count(DISTINCT company.country) AS total_paises
FROM company;

-- 2.3 Identifica la companyia amb la mitjana més gran de vendes.
SELECT company.company_name, AVG(transaction.amount) AS media_ventas
FROM company
JOIN transaction ON company.id = transaction.company_id
GROUP BY company.company_name
ORDER BY media_ventas DESC
LIMIT 10;

-- EXERCICI 3: Utilitzant només subconsultes (sense utilitzar JOIN):
-- 3.1 Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT *
FROM transaction
WHERE company_id IN (
    SELECT id
    FROM company
    WHERE country = 'Germany'
);

-- 3.2 Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions.
SELECT DISTINCT company_name
FROM company
WHERE id IN ( SELECT company_id FROM transaction 
            WHERE amount > ( SELECT AVG(amount) FROM transaction
                            )
);

-- 3.3 Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
SELECT * 
FROM company
WHERE NOT EXISTS (
	SELECT DISTINCT company_id
    FROM TRANSACTION 
    );

-- NIVELL 2

-- EXERCICI 1: Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. Mostra la data de cada transacció juntament amb el total de les vendes.
SELECT 
    DATE(timestamp) AS fecha,
    SUM(amount) AS total_ventas
FROM transaction
WHERE declined = 0
GROUP BY DATE(timestamp)
ORDER BY total_ventas DESC
LIMIT 5;

-- EXERCICI 2: Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà.
SELECT country,
       AVG(transaction.amount) AS mitjana_vendes,
       COUNT(transaction.id) AS num_transaccions
FROM company
JOIN transaction 
  ON transaction.company_id = company.id 
WHERE transaction.declined = 0
GROUP BY country
ORDER BY mitjana_vendes DESC;

-- EXERCICI 3: En la teva empresa, es planteja un nou projecte per a llançar algunes campanyes publicitàries per a fer competència a la companyia "Non Institute". Per a això, et demanen la llista de totes les transaccions realitzades per empreses que estan situades en el mateix país que aquesta companyia.
-- 3.1 Mostra el llistat aplicant JOIN i subconsultes.
SELECT company.company_name,
       transaction.id AS transaction_id,
       DATE(timestamp) AS data_transaccion,
       amount,
       declined
FROM transaction
JOIN company 
  ON company.id = company_id
WHERE country = (
    SELECT country
    FROM company
    WHERE company_name = 'Non Institute'
)
AND declined = 0;

-- 3.2 Mostra el llistat aplicant solament subconsultes.
SELECT 
    (SELECT company_name FROM company WHERE id = transaction.company_id) AS company_name,
    transaction.id AS transaction_id,
    DATE(timestamp) AS data_transaccion,
    amount,
    declined
FROM transaction
WHERE company_id IN (
    SELECT id 
    FROM company 
    WHERE country = (
        SELECT country 
        FROM company 
        WHERE company_name = 'Non Institute'
    )
)
AND declined = 0;

-- NIVELL 3: 
-- EXERCICI 1: Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 350 i 400 euros i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. Ordena els resultats de major a menor quantitat.
 SELECT company_name,
       phone,
       country,
       DATE(transaction.timestamp) AS data_transaction,
       transaction.amount
FROM company
JOIN transaction ON transaction.company_id = company.id
WHERE transaction.amount BETWEEN 350 AND 400
    AND DATE(transaction.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY transaction.amount DESC;

-- EXERCICI 2: Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis si tenen més de 400 transaccions o menys.
SELECT 
    c.company_name,
    c.country,
    COUNT(transaction.id) AS quantitat_transaccions,
    CASE 
        WHEN COUNT(transaction.id) > 400 THEN 'Més de 400 transaccions'
        ELSE 'Menys de 400 transaccions'
    END AS capacitat_operativa
FROM company
LEFT JOIN transaction ON company.id = transaction.company_id
GROUP BY company.company_name, company.country
ORDER BY quantitat_transaccions DESC;
