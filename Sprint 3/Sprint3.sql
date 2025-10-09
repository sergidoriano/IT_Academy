-- NIVELL 1: 
-- EXERCICI 1: Crea la taula credit_card i relaciona-la amb les altres dues taules de la base de dades "transactions".
USE transactions;
CREATE TABLE IF NOT EXISTS credit_card (	-- IF NOT EXISTS sirve para asegurarse de que no estás creando dos veces la misma tabla.
    id VARCHAR(34) PRIMARY KEY,
    iban VARCHAR(34) NOT NULL,
    pan VARCHAR(34) NOT NULL,
    pin VARCHAR(4) NOT NULL,
    cvv VARCHAR(3) NOT NULL,
    expiring_date VARCHAR(10) NOT NULL
);
SELECT * FROM credit_card;

-- Després, introduim les dades del fitxer de "datos_introducir_sprint3_credit"
-- Per últim, la connectem a la taula "transaction" mitjançant una foreign key a credit_card_id.

ALTER TABLE transaction 
ADD FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);

-- EXERCICI 2: Correge el IBAN de la targeta.

UPDATE credit_card
	SET iban = 'TR323456312213576817699999'
    WHERE id = 'CcU-2938'; 

-- ara verifiquem si el canvi s'ha dut a terme correctament: 

SELECT iban 
FROM credit_card
WHERE id = 'CcU-2938';

-- EXERCICI 3: Insereix una nova transacció dins la  taula "transactions":

-- 3.1 completamos primero los datos en las tablas de orígen. Nos inventamos todos los campos faltantes, dado que nos falta la información. 

INSERT INTO company (
    id,
    company_name,
    phone, 
    email,
    country,
    website
) VALUES ( 
    'b-9999',
    'Cal Badejo',
    '618943659',
    'calbadejo@gmail.com', 
    'spain',               
    'calbadejo.com'
);
    
INSERT INTO credit_card (
    id,
    iban,
    pan,
    pin,
    cvv,
    expiring_date
) VALUES ( 
    'CcU-9999',
    'ES8521006743081967253189',  
    '4539672543217896',          
    '2847',                      
    '379',                       
    '08/27/25'                   
);
    
-- Luego hacemos la transacción en la tabla maestra (transactions) como queríamos desde el principio.
-- RECOMENDACIÓN: Debería verificar antes en la tabla transaction que el id de transaction no exista. Es probable que te dé error.

INSERT INTO transaction (
    id,
    credit_card_id,
    company_id, 
    user_id,
    lat,
    longitude,
    amount,
    declined
) VALUES (
    '108B1D1D-5B23-A76C-55EF-C568E49A99DD',
    'CcU-9999',
    'b-9999',
    9999,
    829.999,
    -117.999,
    111.11,
    0
);

-- EXERCICI 4: Eliminar la columna pan de la taula credit_card.
-- RECUERDA!!! Debes hacer captura antes de eliminar la tabla original para probar que existía el pan antes de borrarlo.

ALTER TABLE credit_card
DROP column pan;

SELECT * FROM credit_card;

-- NIVELL 2

-- EXERCICI 1: Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

-- Antes de eliminar nada, es recomendable ver aquello que vamos a eliminar: 

SELECT * FROM transaction 
WHERE transaction.id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- Revisamos los registros que están relacionados con esta ID en las tablas hijas mediante una FOREIGN KEY.
-- Ahora, podemos eliminar sin mayor problema el registro. A diferencia del ejercicio anterior, estamos eliminando un registro de la tabla maestra o principal (la id de transaction). Este dato existe en las otras tablas, pero al ser la tabla maestra su tabla de origen, no hay riesgo de que altere o deje vacíos los registros de otras tablas. Eso si, emplearemos el comando START TRANSACTION, ya que esta agrupa y ejecuta las funciones de forma conjunta y crea una "copia de seguridad" o "snapshot" del bloque. Así, si cometemos un error al eliminar el registro, podemos volver atrás con ROLLUP.

START TRANSACTION;
DELETE FROM transaction
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

COMMIT; 

-- EXERCICI 2: crea una vista de marketing per a la companyia amb les dades següents: Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.

CREATE VIEW MarketingView AS
	SELECT 
		company.company_name AS nombre_compania,
        company.phone AS telefono_contacto,
        company.country AS pais_sede,
        ROUND(AVG(transaction.amount),2) AS media_ventas
	FROM company
    JOIN transaction 
		ON transaction.company_id = company.id
	GROUP BY company.id, company.phone, company.country
    ORDER BY media_ventas DESC; 

    
-- Nota para mí mismo: Recuerda actualizar los schemas después de ejecutar la función.alter

-- EXERCICI 3: Filtra la vista VistaMarketing per a mostrar només les companyies que tenen el seu país de residència en "Germany"

SELECT *
FROM marketingview
WHERE pais_sede = 'Germany';

-- Ahora que tenemos la vista creada, resulta muy sencillo el filtrar los datos que se encuentran dentro de ella. La función nos devuelve solamente 8 de las 101 filas que nos dió originalmente al filtrarla por alemania.

-- NIVELL 3:

-- EXERCICI 1: 

-- 1) Primero, tendrás que crear la estructura de la tabla (presente en el documento "estructura_dades_user" y, seguido introducir los datos presentes en el documento "dades_introduir_user" en cada registro. Como ambos documentos vienen ya definididos, basta solo con ejecutar el código en este orden.
-- 2) Una vez creada la tabla user e introducidos los datos correspondientes en cada campo, solo tendrás que clicar en "Database" --> "Reverse Engenieer". Una vez ahí, aparecerá un panel de control donde deberá introdcir la contraseña de la base de datos (root) y más tarde la base de datos de la cual se quiere establecer el programa. A partir de ahí, solo deberá ejecutar el diagrama y voilà.
-- 3) Sin embargo, la tabla está separada de las demás:
	-- Tendremos que crear un nuevo campo en la tabla transaction que se llame "user_id" (ya estaba creada, pero dejo el código de todas formas).
    
-- ALTER TABLE transaction
-- DROP COLUMN iser_id 


    
-- Luego habrá que que conectarla a la tabla maestra (transacciones) mediante una FOREIGN KEY, creando así una realción de 1 a muchos (1:N) con la tabla user. Pero no nos lo permitirá. En el ejercicio anterior añadimos un registro a la tabla transacctions con el user_id que no existe en la tabla user. Por ello, tendremos que ir a dicha tabla y "solicitar" (inventar) el resto de datos del usuario antes de poder establecer la relación entre ambas tablas: 

INSERT INTO user ( id, name, surname, phone, email, birth_date, country,  city, postal_code, address
    ) VALUES ( '9999', 'Zeus',  'Gamble',  '1-282-581-0551',  'interdum.enim@protonmail.edu',  'Nov 17, 1985', 'United States',  'New York',  '10001',  '348-7818 Sagittis Stransaction.'
);
SELECT* FROM user
WHERE id = '9999';

-- Existe otro problema. Si intentamos unir ambas tamblas mediante una foreign key, veremos que no nos lo permiten porque los tipos de datos de user.id (CHAR) y de transaction.user_id (INT) son incompatibles. Para ello, primero debemos comprovar que no existan ya claves foráneas vinculadas a ninguno de estos campos. Y luego, modificamos el id por INtransaction. 

DESCRIBE user; -- La tabla nos muestra la estructura de la tabla user, incluídas los tipos de datos y las FOREING KEYS presentes. 

ALTER TABLE user 
MODIFY COLUMN id INT; -- Mofificamos el tipo de dato de user.id.

-- Ahora si, deberíamos podemos crear FOREIGN KEY entre las tablas "transaction" y "user".

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_user
FOREIGN KEY (user_id) REFERENCES user(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

-- Así, finalmente obtenemos el diagrama esperado (caputura en el documento).

-- EXERCICI 2:crear una vista anomenada "InformeTecnico" que contingui la següent informació: ID de la transacció, Nom de l'usuari/ària, Cognom de l'usuari/ària, IBAN de la targeta de crèdit usada, Nom de la companyia de la transacció realitzada. Assegureu-vos d'incloure informació rellevant de les taules que coneixereu i utilitzeu àlies per canviar de nom columnes segons calgui.

CREATE OR REPLACE VIEW InformeTecnico AS -- Usamos OR REPLACE para actualizar la vista
SELECT 
    transaction.id AS 'ID_Transaccio',
    user.name AS 'Nom_Usuari',
    user.surname AS 'Cognom_Usuari',
    credit_card.iban AS 'IBAN_Targeta',
    company.company_name AS 'Nom_Companyia',
    transaction.amount AS 'Muntant_transacció',    -- 1. Importe de la transacción
    transaction.declined AS 'Rebutjada',          -- 2. Estado (0 = Éxito, 1 = Fallo)
    user.country AS 'Pais_Usuari'         -- 3. País de origen del usuario
FROM 
    transaction
JOIN 
    user ON transaction.user_id = user.id
JOIN 
    credit_card ON transaction.credit_card_id = credit_card.id
JOIN 
    company ON transaction.company_id = company.id
ORDER BY transaction.id DESC;

SELECT * FROM transactions.informetecnico;
