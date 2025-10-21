-- SPRINT 4: 
-- NIVELL 1:Descàrrega els arxius CSV, estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, almenys 4 taules de les quals puguis realitzar les següents consultes.
-- Per tal de fer aquest exercici, primer haurem de crear la nostra pròpia base de dades (schema") a partir de tots els documents CSV que hem creat. 
CREATE SCHEMA IF NOT EXISTS `Freixenet`;  -- 1. Crear la base de datos (Schema) usando acentos graves (backticks)
USE `Freixenet`; -- 2. Seleccionar la base de datos para trabajar
SET default_storage_engine = INNODB; -- 3. Establecer el motor de almacenamiento correctamente (INNODB)

-- Empezaremos creando las tablas de "dimensiones", las "puntas de la "estrella". 
-- ** tabla PRODUCTS **

CREATE TABLE product (
    id VARCHAR(50) PRIMARY KEY, -- Usamos el ID original del CSV como PK
    product_name VARCHAR(255) NOT NULL,
    price_unit DECIMAL(10, 2), 
    colour VARCHAR(50),
    weight_kg DECIMAL(5, 2),
    warehouse_id VARCHAR(50) -- Renombrado y usado como ID único
);

-- insertamos los datos del CSV "products": 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/products.csv' 
INTO TABLE product 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, product_name, @price, colour, weight_kg, warehouse_id)
SET price_unit = REPLACE(@price, '$', ''); -- Limpieza de dato en la carga 

-- Tabla para COMPANY:

CREATE TABLE company (
    id VARCHAR(50) PRIMARY KEY, 
    company_name VARCHAR(255) NOT NULL,
    country VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    website VARCHAR(255)
);

-- insertamos: 
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/companies.csv'
INTO TABLE company
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, company_name, phone, email, country, website); -- NOTA CLAVE: La lista de columnas (en paréntesis) coincide con el orden del CSV, pero se salta la columna company_pk, permitiendo a AUTO_INCREMENT hacer su trabajo.

-- Tabla CREDIT_CARD: 

CREATE TABLE credit_card (
    id VARCHAR(50) PRIMARY KEY NOT NULL, 
    user_id VARCHAR (50), 
    iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(50), 
    cvv VARCHAR(10), 
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(20) 
);

-- Insertamos: 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/credit_cards.csv'
INTO TABLE credit_card
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- En cuanto a los users, podríamos hacer dos tablas separadas (users americanos y users europeos). Pero una buena práctica del modelo dimensional es combinar datos semejantes en una misma tabla (siempre y cuando tengan los mismos campos). 
-- Podemos convertir la diferencia entre Europeos y Americanos en un simple atributo de la dimensión (una categoría dicotómica), pero para ello hará falta añadir un campo que no existía: país. 

CREATE TABLE user (
    id INT PRIMARY KEY, -- Usamos el ID original como PK
    first_name VARCHAR(100) NOT NULL, 
    last_name VARCHAR(100) NOT NULL, 
    phone VARCHAR(50),
    email VARCHAR(255),
    birth_date DATE, 
    country VARCHAR(100) NOT NULL,
    continent VARCHAR(50) NOT NULL, 
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255)
);

-- Insertamos datos de users AMERICANOS: 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/american_users.csv'
INTO TABLE user
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, first_name, last_name, phone, email, @birth_date_raw, country, city, postal_code, address)
SET 
    continent = 'America',
    birth_date = STR_TO_DATE(@birth_date_raw, '%b %d, %Y'); 
    
-- Insertamos users EUROPEOS: 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/european_users.csv'
INTO TABLE user
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(id, first_name, last_name, phone, email, @birth_date_raw, country, city, postal_code, address)
SET 
    continent = 'Europe',
    birth_date = STR_TO_DATE(@birth_date_raw, '%b %d, %Y');
    
-- Finalmente crearemos la´ÚLTIMA TABLA: transacciones. Esta será la tabla maestra y la más importante, ya que será el centro de nuestro diagrama de estrella. 

USE `Freixenet`; 

CREATE TABLE IF NOT EXISTS transaction (
    -- Clave Primaria
    id VARCHAR(255) PRIMARY KEY, 
    
    -- Claves Foráneas (referencias)
    card_id VARCHAR(50),             -- Referencia a credit_card.id
    company_id VARCHAR(50) NOT NULL,  -- Referencia a company.id
    
    -- Datos Transaccionales
    timestamp DATETIME,              -- Fecha y hora de la transacción
    amount DECIMAL(10, 2) NOT NULL,  -- Monto de la transacción
    declined BOOLEAN,                -- 0 (No) o 1 (Sí)
    product_ids VARCHAR(500),        -- Lista de IDs de productos
    user_id INT NOT NULL,            -- Referencia a user.id
    
    -- Datos Geográficos
    lat DECIMAL(11, 8),              -- Latitud
    longitude DECIMAL(11, 8)         -- Longitud
);

-- Insertamos todos los datos: 

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/transactions.csv'
INTO TABLE transaction
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Ahora veremos que las 5 tablas aparecen separadas entre ellas. Antes de vincularlas mediante Foreign Keys, vamos a crear una nueva columna que indique que es para la Foreign Key, la cual va a coincidir con el id (el id original) de la otra tabla. 

-- 1. Unir a la dimensión USER
ALTER TABLE transaction
    ADD CONSTRAINT fk_user
    FOREIGN KEY (user_id) REFERENCES user(id);
    
-- 2. Unir a la dimensión COMPANY
ALTER TABLE transaction
    ADD CONSTRAINT fk_company
    FOREIGN KEY (company_id) REFERENCES company(id);
    
-- 3. Unir a la dimensión CREDIT_CARD
ALTER TABLE transaction
    ADD CONSTRAINT fk_card
    FOREIGN KEY (card_id) REFERENCES credit_card(id); -- Esta FK falló la primera vez porque los ids de la hoja credit_card.csv y la hoja transactions_csv tienen  prefijos distintos, de forma que JOIN no podía relacionarlas y aparecían como 5000 tarjetas sin coincidencias.
    
-- La tabla de PRODUCT la dejamos para más adelante, como nos recomienda el ejercicio. 

-- EXERCICI 1: Mostrar los usuarios con más de 80 transacciones. 

SELECT
    user.id,
    user.first_name,
    user.last_name,
    -- 1. Subconsulta per calcular el recompte (es calcula una vegada per a cada usuari)
    (
        SELECT COUNT(transaction.id)
        FROM transaction
        WHERE transaction.user_id = user.id -- Correlació per comptar només les transaccions d'aquest usuari
    ) AS num_transactions
FROM
    user
WHERE
    -- 2. Subconsulta per aplicar el filtre (el mateix càlcul es repeteix, però el filtre és ràpid)
    (
        SELECT COUNT(transaction.id)
        FROM transaction
        WHERE transaction.user_id = user.id
    ) > 80
ORDER BY
    num_transactions DESC;

-- EXERCICI 2: Media de Amount por IBAN para "Donec Ltd"

SELECT
    credit_card.iban,
    ROUND(AVG(transaction.amount), 2) AS mitjana_amount_€
FROM transaction
JOIN credit_card
    ON credit_card.id = transaction.card_id
JOIN company
    ON company.id = transaction.company_id 
WHERE company.company_name = 'Donec Ltd' 
GROUP BY credit_card.iban
ORDER BY mitjana_amount_€ DESC;

-- NIVELL 2

-- EXERCICI 1: Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions han estat declinades aleshores és inactiu, si almenys una no és rebutjada aleshores és actiu. Partint d’aquesta taula respon:

-- A) Creem una nova taula
 
CREATE TABLE card_status_simple AS
SELECT t.card_id, (
        SELECT t3.timestamp
        FROM transaction t3
        WHERE t3.card_id = t.card_id
        ORDER BY t3.timestamp DESC
        LIMIT 1 OFFSET 2 -- Selecciona només la 3a fila (offset 2)
    ) AS third_recent_timestamp -- La subconsulta troba la data de la 3a transacció més recent per a cada targeta. Si una targeta té menys de 3 transaccions, aquesta data serà NULL.
FROM transaction t
GROUP BY t.card_id; -- Agrupem per obtenir una sola fila per a cada targeta
    
-- B) Calcular l'Estat Final Utilitzant la Data Clau.
-- Pas 2: Afegim una columna a la taula anterior que contingui el nombre de rebutjos des de la tercera transacció

ALTER TABLE card_status_simple
ADD COLUMN status_targeta VARCHAR(10); -- Afegim la columna de l'estat

-- Pas 3: Actualitzem l'estat basant-nos en les condicions

SET SQL_SAFE_UPDATES = 0; -- Deshabilita la protecció per defecte de MySQL.
UPDATE card_status_simple cs

SET status_targeta = (
    -- Subconsulta que comprova les condicions
    SELECT
        CASE
            -- CAS 1: Si third_recent_timestamp és NULL (la targeta té < 3 transaccions), és ACTIVA
            WHEN cs.third_recent_timestamp IS NULL THEN 'Actiu'
            
            -- CAS 2: Comprovem si alguna transacció (des de la 3a més recent) NO va ser rebutjada (declined = 0)
            WHEN EXISTS (
                SELECT 1
                FROM transaction t_check
                WHERE 
                    t_check.card_id = cs.card_id AND -- Per a la targeta actual
                    t_check.timestamp >= cs.third_recent_timestamp AND -- Des de la tercera transacció...
                    t_check.declined = 0 -- ...algun rebuig és 0 (actiu)
            ) THEN 'Actiu'
            
            -- CAS 3: Si no es compleix cap de les anteriors, significa que les 3 o més recents van ser rebutjades (Inactiu)
            ELSE 'Inactiu'
        END
);

-- C) Quantes targetes estan actives?
SELECT
    COUNT(css.card_id) AS total_targetes_actives
FROM
    card_status_simple css
WHERE
    css.status_targeta = 'Actiu';
    
-- NIVELL 3: Crea una taula pont entre la taula products i transactions. 

CREATE TABLE product_transaction (
    product_id VARCHAR(50) NOT NULL, 
    transaction_id VARCHAR(255) NOT NULL, 
    PRIMARY KEY (product_id, transaction_id) 
);

-- 1. Afegim la clau forana a la taula de fets (Transaction)
ALTER TABLE product_transaction
    ADD CONSTRAINT fk_product_transaction
    FOREIGN KEY (transaction_id) REFERENCES transaction(id);
    
  -- 2. Afegir la clau forana a la taula de dimensions (Product)
ALTER TABLE product_transaction
    ADD CONSTRAINT fk_pt_product
    FOREIGN KEY (product_id) REFERENCES product(id);  


-- A pesar de que la tabla fuente está construida y que está conectada correctamente a las tablas correspondientes mediante FOREIGN KEYS, esta se encuentra aún vacía. Tenemos que añadir datos:

-- Insereix els valors desglossats a la taula pont

INSERT INTO product_transaction (transaction_id, product_id) -- Indica al servidor que volem afegir noves files a la taula product_transaction, omplint les columnes transaction_id i product_id.
SELECT transaction.id AS transaction_id,
TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(transaction.product_ids, ',', n.n), ',', -1)) AS product_id -- L'Extracció i Neteja del product_id Aquesta és la línia més complexa. Utilitza la funció TRIM() per netejar els espais introduïts pel desglossament i les funcions SUBSTRING_INDEX per aïllar l'ID d'un producte de la llista. Aquest valor s'assigna a la columna product_id.
FROM transaction
JOIN 
	(SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n -- (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
	ON CHAR_LENGTH(transaction.product_ids) - CHAR_LENGTH(REPLACE(transaction.product_ids, ',', '')) >= n.n - 1 -- La Condició de Multiplicació Aquesta és la condició que controla el JOIN. Compara la quantitat de comes (que és un menys que el nombre de productes) amb el número de la taula n. Si una transacció té 3 productes (2 comes), aquesta condició farà que la fila de la transacció s'uneixi amb els números 1, 2 i 3, però no amb el 4 ni el 5.
WHERE TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(transaction.product_ids, ',', n.n), ',', -1)) IS NOT NULL -- Evitar IDs Nuls o Buidats Aquesta condició fa exactament el mateix procés d'extracció que la Línia 4, però assegura que el resultat final no sigui un valor nul (no existeix un producte)
	AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(transaction.product_ids, ',', n.n), ',', -1)) != ''; -- Evitar Cadenes Buides Aquesta condició addicional assegura que el resultat final no sigui una cadena buida ('').


-- EXERCICI 1: Quaàntes vegades s'ha venut cada producte?

SELECT
    product.id,
    product.product_name,
    COUNT(product_transaction.product_id) AS Nombre_de_vendes
FROM product_transaction 
JOIN product
    ON product_transaction.product_id = product.id
GROUP BY product.id, product.product_name
ORDER BY Nombre_de_vendes DESC, product.product_name ASC;