SET SERVEROUTPUT ON;

-----PACKAGE traveler_assistance_package-----
CREATE OR REPLACE PACKAGE traveler_assistance_package AS
/* ex2. create a record type with appropiate components */
TYPE rec_region_and_currency IS RECORD(
country_name countries.country_name%TYPE,
region regions.region_name%TYPE,
currency currencies.currency_name%TYPE
);
--create table
TYPE citsr_table_type IS TABLE OF rec_region_and_currency INDEX BY BINARY_INTEGER;
/* ex5. create a record type with appropiate components */
TYPE rec_language IS RECORD(
        country_name COUNTRIES.country_name%TYPE,
        language_name LANGUAGES.language_name%TYPE,
        official_language SPOKEN_LANGUAGES.official%TYPE
    );
-- create table
TYPE languages_table_type IS TABLE OF rec_language INDEX BY BINARY_INTEGER;    

-----Procedure 1-----
    /* The procedure accepts the 'country name' parameter so we can display neccesary informations */
    PROCEDURE country_demographics(p_country_name IN countries.country_name%type);
    /* The procedure accepts the 'country name' parameter so we can display region and currency using record type*/
    PROCEDURE find_region_and_currency(p_country_name IN countries.country_name%type, p_region_and_currency OUT rec_region_and_currency);
    /* The procedure accepts region_name as IN paramther and associacive array as an OUT paramether */
    PROCEDURE countries_in_the_same_region(p_region_name IN regions.region_name%TYPE, p_citsr_table OUT  citsr_table_type);
    /*The procedure to display array from countries_in_the_same_region) */
    PROCEDURE print_region_array(pitsr_array citsr_table_type);
    /*The procedure to return all the spoken languages and spoken languages in country */
    PROCEDURE country_languages(p_country_name IN countries.country_name%type, p_languages_array OUT languages_table_type);
    /*The procedure to display array from  country_languages*/
    PROCEDURE print_language_array(languages_array IN languages_table_type);
     
END traveler_assistance_package;
/
CREATE OR REPLACE PACKAGE BODY traveler_assistance_package
AS
-- PROCEDURE 1 --
PROCEDURE country_demographics (p_country_name IN countries.country_name%type) AS
l_country countries%ROWTYPE;
    BEGIN
        -- implicit cursor
        SELECT * INTO l_country FROM countries WHERE (LOWER(country_name) = LOWER(p_country_name));
        DBMS_OUTPUT.PUT_LINE(l_country.COUNTRY_NAME || ',  ' || l_country.LOCATION || ', ' || l_country.POPULATION
                                 || ', ' || l_country.AIRPORTS || ', ' || l_country.CLIMATE);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20201, 'Cannot found country: ' || p_country_name);            
    END country_demographics;
-- PROCEDURE 2 --    
PROCEDURE find_region_and_currency(p_country_name IN countries.country_name%type, p_region_and_currency OUT rec_region_and_currency) AS
    BEGIN
        SELECT c.country_name, r.region_name, cu.currency_name INTO p_region_and_currency
        FROM COUNTRIES c, REGIONS r, CURRENCIES cu
        WHERE LOWER(c.COUNTRY_NAME) = LOWER(p_country_name)AND
                c.REGION_ID = r.REGION_ID AND
                c.CURRENCY_CODE = cu.CURRENCY_CODE;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'No data found for country ' || p_country_name);
    END find_region_and_currency;
-- PROCEDURE 3 --
PROCEDURE countries_in_the_same_region(p_region_name IN regions.region_name%TYPE, p_citsr_table OUT  citsr_table_type)AS
--Create cursor to get an pointor to informations that we want;
 CURSOR c1 IS
           SELECT c.country_name, r.region_name, cu.currency_name
           FROM COUNTRIES c, REGIONS r, CURRENCIES cu
           WHERE LOWER(r.region_name) = LOWER(p_region_name) AND
            r.region_id = c.region_id AND
            c.currency_code = cu.currency_code;
iterator BINARY_INTEGER := 1;
--Create a flag to inform us about exception
l_flag NUMBER := 0;
    BEGIN
       -- For loop to fill  array
       FOR i IN c1 LOOP
       -- if flag == 1 then exception is no needed
       l_flag := 1;
       -- fill array
       p_citsr_table(iterator) := i;
       iterator := iterator+1;
       END LOOP;
       IF l_FLAG = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'No data found for region' || p_region_name);
       END IF;
    END countries_in_the_same_region;
-- PROCEDURE 4 --
PROCEDURE print_region_array(pitsr_array IN citsr_table_type) AS
    BEGIN
        FOR i IN pitsr_array.FIRST .. pitsr_array.LAST LOOP
            DBMS_OUTPUT.PUT_LINE(pitsr_array(i).country_name || ', ' || pitsr_array(i).region || ', ' || pitsr_array(i).currency);
        END LOOP;
        
    END;
-- PROCEDURE 5--    
PROCEDURE country_languages(p_country_name IN countries.country_name%type, p_languages_array OUT languages_table_type) AS
CURSOR languages_cur IS 
                    SELECT c.country_name, l.language_name, sl.official
                    FROM countries c, languages l, spoken_languages sl
                    WHERE LOWER(c.country_name) = LOWER(p_country_name) AND
                    c.country_id = sl.country_id AND
                    sl.language_id = l.language_id;
iterator BINARY_INTEGER := 1;
--Create a flag to inform us about exception
l_flag NUMBER := 0;
    BEGIN
           -- For loop to fill  array
    FOR i IN languages_cur LOOP
        -- if flag == 1 then exception is no needed
        l_flag := 1;
        -- fill array
        p_languages_array(iterator) := i;
        iterator := iterator + 1;
    END LOOP;
    IF l_FLAG = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'No data found for country ' || p_country_name);
       END IF;
    END country_languages;
-- PROCEDURE 6 --
PROCEDURE print_language_array(languages_array IN languages_table_type) AS
BEGIN
    FOR i IN languages_array.FIRST .. languages_array.LAST LOOP
    DBMS_OUTPUT.PUT_LINE(languages_array(i).country_name || ', ' || languages_array(i).language_name || ', ' || languages_array(i).official_language);
    END LOOP;
END print_language_array;

END traveler_assistance_package;
/


--==== TESTS =====--
-- country_demographics test --
BEGIN
--works
traveler_assistance_package.country_demographics('Canada');
-- not work :( EXCEPTION
traveler_assistance_package.country_demographics('RepublicOfPancakes');
END;
/
-- find_region_and_currency test--
DECLARE
region_and_currency_out traveler_assistance_package.rec_region_and_currency;
BEGIN
-- works
traveler_assistance_package.find_region_and_currency('Greenland',region_and_currency_out);
DBMS_OUTPUT.PUT_LINE(region_and_currency_out.country_name || ', ' ||region_and_currency_out.region || ', ' || region_and_currency_out.currency);
-- not work :( EXCEPTION
traveler_assistance_package.find_region_and_currency('Anycountry',region_and_currency_out);
END;
/
--countries_in_the_same_region test-- 
DECLARE
mytable traveler_assistance_package.citsr_table_type;
wrong_region_name regions.region_name%type := 'Funny region';
region_name regions.region_name%type := 'Central America';
BEGIN
-- works
traveler_assistance_package.countries_in_the_same_region(region_name, mytable);
DBMS_OUTPUT.PUT_LINE('Countires in region: ' || region_name);
traveler_assistance_package.print_region_array(mytable);
-- not work :( EXCEPTION
traveler_assistance_package.countries_in_the_same_region(wrong_region_name, mytable);
END;
/
--country_languages test--
DECLARE
mytable traveler_assistance_package.languages_table_type;
wrong_country_name countries.country_name%type := 'BleBelize';
country_name countries.country_name%type := 'Canada';
-- works
BEGIN
-- works
traveler_assistance_package.country_languages(country_name, mytable);
DBMS_OUTPUT.PUT_LINE('Languages in country: ' || country_name);
traveler_assistance_package.print_language_array(mytable);
--not work :( EXCEPTION
traveler_assistance_package.country_languages(wrong_country_name, mytable);
END;
/
