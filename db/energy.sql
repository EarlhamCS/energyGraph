--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: numberGen(smallint, double precision, double precision, double precision[]); Type: FUNCTION; Schema: public; Owner: energy
--

CREATE OR REPLACE FUNCTION numberGen(occ smallint, envelope double precision, degreedays double precision, weights double precision[]) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    ret numeric;
BEGIN
    ret := 1;
    if occ IS NOT NULL THEN
        ret := ret / occ ;
    END IF;
    IF envelope IS NOT NULL THEN
        ret := ret / envelope ;
    END IF;
    IF degreeDays IS NOT NULL THEN
        ret := ret / degreeDays ;
    END IF;
    RETURN ret;
    END;
$$;


ALTER FUNCTION public.numberGen(occ smallint, envelope double precision, degreedays double precision, weights double precision[]) OWNER TO energy;


--
-- Name: numberTrans(character varying, numeric, numeric[]); Type: FUNCTION; Schema: public; Owner: energy
--

CREATE OR REPLACE FUNCTION numberTrans(area character varying, preal numeric, numbers numeric[]) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    scaleConstant numeric;
BEGIN
    scaleConstant := 1.0 / numbers[1];
    IF area = 'Bundy' THEN
      RETURN preal * numbers[1] * scaleConstant;
    ELSIF area = 'EH' THEN
      RETURN preal * numbers[2] * scaleConstant;
    ELSIF area = 'OA' THEN
      RETURN preal * numbers[3] * scaleConstant;
    ELSIF AREA = 'Mills' THEN
      RETURN preal * numbers[4] * scaleConstant;
    ELSIF AREA = 'Hoerner' THEN
      RETURN preal * numbers[5] * scaleConstant;
    ELSIF AREA = 'Warren' THEN
      RETURN preal * numbers[6] * scaleConstant;
    ELSIF AREA = 'Wilson' THEN
      RETURN preal * numbers[7] * scaleConstant;
    ELSIF area = 'Barrett' THEN
      RETURN preal * numbers[8] * scaleConstant;
    ELSE
      RETURN -1.0;
END IF;
END;
$$;


ALTER FUNCTION public.numberTrans(area character varying, preal numeric, numbers numeric[]) OWNER TO energy;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: b1; Type: TABLE; Schema: public; Owner: energy; Tablespace: 
--

CREATE TABLE b1 (
    area character varying(32),
    preal numeric(5,1),
    date timestamp without time zone
);


ALTER TABLE public.b1 OWNER TO energy;

--
-- Name: bundy_baseline; Type: TABLE; Schema: public; Owner: energy; Tablespace: 
--

CREATE TABLE bundy_baseline (
    area character varying(32),
    preal numeric(5,1),
    date timestamp without time zone
);


ALTER TABLE public.bundy_baseline OWNER TO energy;

--
-- Name: electrical_energy; Type: TABLE; Schema: public; Owner: energy; Tablespace: 
--

CREATE TABLE electrical_energy (
    area character varying(32),
    preal numeric(5,1),
    date timestamp without time zone
);


ALTER TABLE public.electrical_energy OWNER TO energy;

--
-- Name: electrical_energy_backup_1; Type: TABLE; Schema: public; Owner: energy; Tablespace: 
--

CREATE TABLE electrical_energy_backup_1 (
    area character varying(32),
    preal numeric(5,1),
    date timestamp without time zone
);


ALTER TABLE public.electrical_energy_backup_1 OWNER TO energy;

--
-- Name: electrical_energy_rpnl; Type: TABLE; Schema: public; Owner: energy; Tablespace: 
--

CREATE TABLE electrical_energy_rpnl (
    area text,
    address text,
    date timestamp without time zone,
    preal integer,
    preal_change integer
);


ALTER TABLE public.electrical_energy_rpnl OWNER TO energy;

--
-- Name: normparams; Type: TABLE; Schema: public; Owner: energy; Tablespace: 
--

CREATE TABLE normparams (
    area character varying(32),
    occupancy smallint,
    envelope double precision,
    degreedays double precision,
    weights double precision[],
    date timestamp without time zone
);


ALTER TABLE public.normparams OWNER TO energy;

--
-- Name: numbers; Type: VIEW; Schema: public; Owner: energy
--

CREATE VIEW numbers AS
    SELECT normparams.area, numberGen(normparams.occupancy, normparams.envelope, normparams.degreedays, normparams.weights) AS buildingnum, normparams.date FROM normparams;


ALTER TABLE public.numbers OWNER TO energy;

--
-- Name: normed_electrical_energy; Type: VIEW; Schema: public; Owner: energy
--

CREATE VIEW normed_electrical_energy AS
    SELECT electrical_energy.area, numberTrans(electrical_energy.area, electrical_energy.preal, (SELECT array_agg(numbers.buildingnum) AS array_agg FROM numbers WHERE ((numbers.area)::text = ANY ((ARRAY['Bundy'::character varying, 'Barrett'::character varying, 'EH'::character varying, 'OA'::character varying, 'Mills'::character varying, 'Hoerner'::character varying, 'Warren'::character varying, 'Wilson'::character varying])::text[])))) AS preal, electrical_energy.date FROM electrical_energy WHERE ((electrical_energy.area)::text = ANY ((ARRAY['Bundy'::character varying, 'Barrett'::character varying, 'EH'::character varying, 'OA'::character varying, 'Mills'::character varying, 'Hoerner'::character varying, 'Warren'::character varying, 'Wilson'::character varying])::text[]));


ALTER TABLE public.normed_electrical_energy OWNER TO energy;

--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: electrical_energy; Type: ACL; Schema: public; Owner: energy
--

REVOKE ALL ON TABLE electrical_energy FROM PUBLIC;
REVOKE ALL ON TABLE electrical_energy FROM energy;
GRANT ALL ON TABLE electrical_energy TO energy;
GRANT SELECT ON TABLE electrical_energy TO PUBLIC;


--
-- PostgreSQL database dump complete
--

