-- Script para cargar datos de independientes desde agente.json
-- Ejecutar después de 01_params_pui.sql

-- Limpiar tabla si existe
TRUNCATE TABLE independientes_asociacion;

-- Insertar todos los comercializadores independientes
-- Los que tienen miembro = true están asociados a la empresa contratante
-- Los que tienen miembro = false son otros independientes

INSERT INTO independientes_asociacion (agente_code, agente_nombre, es_miembro_asociacion) VALUES
-- Miembros de la asociación que pagó el estudio (miembro = true)
('ASCC', 'A.S.C. INGENIERIA S.A. E.S.P.', true),
('CBNC', 'COLOMBINA ENERGIA SAS ESP', true),
('DEPC', 'DEPI ENERGY S.A.S. E.S.P.', true),
('DLRC', 'DICELER S.A. E.S.P.', true),
('NRCC', 'ENERCO S.A. E.S.P.', true),
('EGTC', 'ENERGETICOS S.A.S E.S.P', true),
('EYCC', 'ENERGIA Y GAS DE COLOMBIA SAS ESP', true),
('ETTC', 'ENERTOTAL S.A. E.S.P.', true),
('EXIC', 'ENERXIA COLOMBIA SAS ESP - COMERCIALIZADOR', true),
('FERC', 'FUENTES DE ENERGIAS RENOVABLES S.A.S. E.S.P.', true),
('ITLC', 'ITALCOL ENERGIA S.A. E.S.P.', true),
('JRDC', 'JULIA - RD S.A. E.S.P.', true),
('MERC', 'MERELEC COLOMBIA S.A.S. E.S.P.', true),
('NEUC', 'NEU ENERGY S.A.S E.S.P', true),
('QIEC', 'QI ENERGY S.A.S. E.S.P.', true),
('RTQC', 'RUITOQUE S.A. E.S.P.', true),
('SFEC', 'SANTA FE ENERGY ZOMAC S.A.S. E.S.P.', true),
('SCEC', 'SOL & CIELO ENERGIA S.A.S. E.S.P', true),
('GNCC', 'VATIA S.A. E.S.P.', true),

-- Otros independientes sin asociación (miembro = false)
('AMPC', 'AMPERIA S.A. E.S.P.', false),
('BEIC', 'BEAM ENERGY INNOVATION S.A.S. E.S.P.', false),
('CBYC', 'CARBOENERGY SAS ESP', false),
('CERC', 'CEE ENERGY SAS ESP', false),
('CMXC', 'CEMEX ENERGY S.A.S E.S.P.', false),
('CNRC', 'COENERSA S.A.S. E.S.P.', false),
('COLC', 'COLENERGIA S.A. E.S.P.', false),
('DMRC', 'DEMAND RESPONSE SAS ESP', false),
('DRUC', 'DRUMMOND POWER S.A.S. E.S.P.', false),
('DUCC', 'DUCK ENERGY S.A.S ESP', false),
('EFEC', 'E2 ENERGIA EFICIENTE S.A. E.S.P.', false),
('EMMC', 'ECOMMERCIAL S.A.S. E.S.P.', false),
('ESVC', 'EMPRESA SIGLO XXI EICE ESP', false),
('ENBC', 'ENERBIT S.A.S. E.S.P.', false),
('ELIC', 'ENERGIA LIMPIA Y EFICIENTE S.A.S ESP', false),
('NMRC', 'ENERMAS SAS ESP', false),
('ENVC', 'ENERVISA S.A.S E.S.P.', false),
('ERNC', 'ÉRGON ENERGY SAS ESP', false),
('SPRC', 'ESPACIO PRODUCTIVO S.A.S. E.S.P.', false),
('FREC', 'FRANCA ENERGIA SA ESP', false),
('GAPC', 'GAP ENERGY GROUP SAS ESP', false),
('GWOC', 'GREENWOOD ENERGY S.A.S. E.S.P', false),
('GNYC', 'GREENYELLOW COMERCIALIZADORA S.A.S. E.S.P.', false),
('GREC', 'GRUPO ENERGÉTICO SA ESP', false),
('IAEC', 'IA ENERGÍA Y GESTIÓN S.A.S. E.S.P.', false),
('LTEC', 'LATINOAMERICAN ENERGY S.A.S E.S.P.', false),
('LMEC', 'LUMINA ENERGY S.A.S. E.S.P.', false),
('LESC', 'MESSER ENERGY SERVICES SAS ESP', false),
('NEXC', 'NEXTGY S.A.S. E.S.P', false),
('PLSC', 'PLUSENERGY S.A.S. E.S.P.', false),
('PRYC', 'PROENERGY S.A.S.E.S.P.', false),
('PEEC', 'PROFESIONALES EN ENERGIA S.A. E.S.P.', false),
('RPEC', 'RIOPAILA ENERGÍA S.A.S. E.S.P.', false),
('SMTC', 'SMARTEN S.A.S. E.S.P.', false),
('SEJC', 'SOL DEL EJE S.A.S E.S.P', false),
('SOUC', 'SOUL ENERGY SAS ESP', false),
('SOEC', 'SOUTH32 ENERGY S.A.S E.S.P', false),
('RTAC', 'SPECTRUM RENOVAVEIS S.A.S. E.S.P.', false),
('TPLC', 'TERPEL ENERGÍA S.A.S. E.S.P.', false),
('UNGC', 'UNERGY ENERGY DIGITAL S.A.S E.S.P', false),
('VESC', 'VOLTAJE EMPRESARIAL S.A.S. E.S.P.', false);

-- Verificar carga
SELECT 
    COUNT(*) AS total_agentes,
    SUM(CASE WHEN es_miembro_asociacion THEN 1 ELSE 0 END) AS asociados,
    SUM(CASE WHEN NOT es_miembro_asociacion THEN 1 ELSE 0 END) AS no_asociados
FROM independientes_asociacion;