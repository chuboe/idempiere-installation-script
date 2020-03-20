-- The purpose of this file is to help you restore a 10+ postgres export to a 9.6- instance.
-- Simply include this file with your restore script.
-- This file can be removed from the installation repository when postgresql 9.6 is no longer popular.
-- https://groups.google.com/forum/#!msg/idempiere/DeqZmqTU7Sk/__j-Nil5DwAJ

--------------------- No operator matches the given name and argument type(s). ---------------------
--------------------- You might need to add explicit type casts. ----------------------------------------

--
-- Name: +; Type: OPERATOR; Schema: adempiere; Owner: adempiere
--

CREATE OPERATOR adempiere.+ (
PROCEDURE = adempiere.adddays,
LEFTARG = timestamp with time zone,
RIGHTARG = numeric,
COMMUTATOR = OPERATOR(adempiere.+)
);


ALTER OPERATOR adempiere.+ (timestamp with time zone, numeric) OWNER TO adempiere;

--
-- Name: +; Type: OPERATOR; Schema: adempiere; Owner: adempiere
--

CREATE OPERATOR adempiere.+ (
PROCEDURE = adempiere.adddays,
LEFTARG = interval,
RIGHTARG = numeric,
COMMUTATOR = OPERATOR(adempiere.-)
);


ALTER OPERATOR adempiere.+ (interval, numeric) OWNER TO adempiere;

--
-- Name: -; Type: OPERATOR; Schema: adempiere; Owner: adempiere
--

CREATE OPERATOR adempiere.- (
PROCEDURE = adempiere.subtractdays,
LEFTARG = timestamp with time zone,
RIGHTARG = numeric,
COMMUTATOR = OPERATOR(adempiere.-)
);


ALTER OPERATOR adempiere.- (timestamp with time zone, numeric) OWNER TO adempiere;

--
-- Name: -; Type: OPERATOR; Schema: adempiere; Owner: adempiere
--

CREATE OPERATOR adempiere.- (
PROCEDURE = adempiere.subtractdays,
LEFTARG = interval,
RIGHTARG = numeric,
COMMUTATOR = OPERATOR(adempiere.-)
);


ALTER OPERATOR adempiere.- (interval, numeric) OWNER TO adempiere;

--------------------------------------------------------------
