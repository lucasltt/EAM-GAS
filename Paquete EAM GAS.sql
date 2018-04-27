create or replace package EAM_EPM is

  -- Creación
  -- Version : 1.0
  -- Author  : Lucas Turchet
  -- Created : 23/02/18
  -- Purpose : Disponibilización de Activos para Integración con EAM GAS

  -- Modificación
  -- Version : 1.1
  -- Author  : Lucas Turchet
  -- Created : 02/03/18
  -- 1.   Adición de Reglas de Activos Retirados
  -- 2.   Adición de Reglas de Actualización de Fechas

  -- Modificación
  -- Version : 1.2
  -- Author  : Lucas Turchet
  -- Created : 06/03/18
  -- 1.   Cada ejecución tiene una fecha solo
  -- 2.   Fecha de actualización para Ubicación
  -- 3.   Función de Respaldar Tablas
  -- 4.   Función de Limpiar Tablas
  -- 5.   Recla de Nodo Primario para los Ramales

  -- Modificación
  -- Version : 1.3
  -- Author  : Lucas Turchet
  -- Created : 13/03/18
  -- 1.   Reglas de nombramiento de activos
  -- 2.   Taxonomia de Protección Catodica
  -- 3.   Taxonomia de Celda Kirks
  -- 4.   Ubicacion Inteligente para circuitos y ramales
  --      (no se cambia el codigo de la ubicación al reemplazar el elemento padre)
  -- 5.   Campo REGION en la tabla de activos
  -- 6.   Reglas de códigos de ubicación
  -- 7.   Nueva selección de los circuitos disponibles
  -- 8.   Inserción de la clase 'Estación Valvulas de Derivación'

  -- Correción
  -- Version : 1.3.1
  -- Author  : Lucas Turchet
  -- Created : 14/03/18
  -- 1.   Códigos de Ubicacion

  -- Correción
  -- Version : 1.3.2
  -- Author  : Lucas Turchet
  -- Created : 15/03/18
  -- 1.   Correcion Nivel Superior Ubicacion
  -- 2.   Nueva columnas tablas de activos

  -- Correción
  -- Version : 1.3.3
  -- Author  : Lucas Turchet
  -- Created : 23/03/18
  -- 1.   Correcion Activos de nivel 7  con nivel superior nulo
  -- 2.   Correcion Válvulas primarias con tipo_red vs clase inconsistente

  -- Correción
  -- Version : 1.3.4
  -- Author  : Lucas Turchet
  -- Created : 04/04/18
  -- 1.   No se insertan más los activos que no tienen valvula padre
  -- 2.   No se intertan más los tramos con bifurcaciones
  -- 3.   Los activos de nivel 6 no tiene más el nível superior poblado
  -- 4.   Correción de la ubicación de activos de circuitos.

  -- Correción
  -- Version : 1.3.5
  -- Author  : Lucas Turchet
  -- Created : 05/04/18
  -- 1.  Inserción de las valvula de seccionamiento.

  -- Correción
  -- Version : 1.3.6
  -- Author  : Lucas Turchet
  -- Created : 25/04/18
  -- 1.  Manejo retirados parciales
  
  -- Correción
  -- Version : 1.3.7
  -- Author  : Lucas Turchet
  -- Created : 26/04/18
  -- 1.  Nuevo algoritmo para identificacion de novedades

  -- Busca los elementos de un Número de Tramo Específico
  function EAM_TRACETRAMOESPECIFICO(nrTramo IN NUMBER) return EAM_TRACE_TABLE;

  -- Hace el trace basado en las reglas de tramos
  function EAM_TRACETRAMOS(pFid          IN NUMBER,
                           pNodoAnterior IN NUMBER,
                           pActivo       IN NUMBER,
                           pOrdem        IN NUMBER,
                           pDatos        IN EAM_TRACE_TABLE DEFAULT EAM_TRACE_TABLE())
    return EAM_TRACE_TABLE;

  -- Hace el trace basado en las reglas de Ramales
  function EAM_TRACERAMALES(pFidInicial   IN NUMBER,
                            pCircuito     IN VARCHAR,
                            pNodoAnterior IN NUMBER,
                            pDatos        IN EAM_TRACE_TABLE DEFAULT EAM_TRACE_TABLE())
    return EAM_TRACE_TABLE;

  -- Ejecuta toda la taxonima de GAS
  procedure EAM_TAXONOMIA;

  -- Limpar el contenido de las tablas:
  -- EAM_ACTIVOS
  -- EAM_ACTIVOS_RET
  -- EAM_UBICACION
  procedure EAM_LIMPIAR_TABLAS;

  -- Crea tablas respaldo de las tablas:
  -- EAM_ACTIVOS (EAM_ACTIVOS_BKP)
  -- EAM_ACTIVOS_RET (EAM_ACTIVOS_RET_BKP)
  -- EAM_UBICACION (EAM_UBICACION_BKP)
  procedure EAM_RESPALDAR_TABLAS;

  -- Mira si el activo pertenence a la Red Metropolitana
  function EAM_ESMETROPOLITANA(pFID IN NUMBER, pFNO in NUMBER) return number;

end EAM_EPM;
/
create or replace package body EAM_EPM is

  function EAM_TRACETRAMOESPECIFICO(nrTramo IN NUMBER) return EAM_TRACE_TABLE as
  
    vNodo1 NUMBER(10);
    vNodo2 NUMBER(10);
    vFNO   NUMBER(5);
    vFID   NUMBER(10);
    vCount NUMBER;
  
    vResult EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vDatos  EAM_TRACE_TABLE := EAM_TRACE_TABLE();
  
  begin
  
    for valvula in (select valor as valvula_fid
                      from eam_config
                     where descripcion = 'TRAMO') loop
    
      select nodo1_id, nodo2_id, g3e_fno, g3e_fid
        into vNodo1, vNodo2, vFNO, vFID
        from cconectividad_g
       where g3e_fid = valvula.valvula_fid;
    
      vDatos := EAM_TRACE_TABLE();
    
      vResult := EAM_TRACETRAMOS(vFID, vNodo1, nrTramo, 1, vDatos);
    
      select count(1)
        into vCount
        from table(vResult) t
       where t.tipo = 'TRAMO_' || nrTramo;
    
      if vCount > 0 then
        return vResult;
      end if;
    
      vDatos := EAM_TRACE_TABLE();
    
      vResult := EAM_TRACETRAMOS(vFID, vNodo2, nrTramo, 1, vDatos);
    
      select count(1)
        into vCount
        from table(vResult) t
       where t.tipo = 'TRAMO_' || nrTramo;
    
      if vCount > 0 then
        return vResult;
      end if;
    
    end loop;
  
    return vResult;
  end;

  function EAM_TRACETRAMOS(pFid          IN NUMBER,
                           pNodoAnterior IN NUMBER,
                           pActivo       IN NUMBER,
                           pOrdem        IN NUMBER,
                           pDatos        IN EAM_TRACE_TABLE DEFAULT EAM_TRACE_TABLE())
    return EAM_TRACE_TABLE as
  
    --HACE EL TRACE PARA CREAR LOS TRAMOS
    vEAM1   EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vEAM2   EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vNodo1  NUMBER(10);
    vNodo2  NUMBER(10);
    vFNO    NUMBER(5);
    vFID    NUMBER(10);
    vCount  NUMBER;
    vStop   NUMBER;
    vActivo NUMBER;
    vOrdem  NUMBER;
    vTipo   VARCHAR2(30);
    vResult EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vResTem EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vDatos  EAM_TRACE_TABLE := pDatos;
  
    cursor nodos(vFid number, nodo number) is
      select *
        from cconectividad_g
       where g3e_fid <> vFid
         and (nodo1_id = nvl(nullif(nodo, 0), -1) or
             nodo2_id = nvl(nullif(nodo, 0), -1));
  
  begin
  
    --Verificar si el registro ya fue procesado y no tene run loop infinito
    select /* parallel */
     count(1)
      into vCount
      from table(vDatos)
     where g3e_fid = pFid;
  
    if vCount > 0 then
      return vResult;
    else
      vDatos.extend();
      vDatos(vDatos.COUNT) := eam_trace_record(null,
                                               pFid,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null);
    end if;
  
    vActivo := pActivo;
    vOrdem  := pOrdem;
  
    --NOW WE NEED TO GET THE NODE1 AND NODE2 OF THE PROVIDED G3E_ID
    select nodo1_id, nodo2_id, g3e_fno, g3e_fid
      into vNodo1, vNodo2, vFNO, vFID
      from cconectividad_g
     where g3e_fid = pFid;
  
    --NOW I HAVE TO CHECK THE NODES CONNECTING TO NODE1
    if vnodo1 != pNodoAnterior then
      for nodo in nodos(vFID, vnodo1) loop
        vEAM1.extend();
        vEAM1(vEAM1.COUNT) := eam_trace_record(nodo.g3e_id,
                                               nodo.g3e_fid,
                                               nodo.g3e_fno,
                                               nodo.nodo1_id,
                                               nodo.nodo2_id,
                                               vActivo,
                                               vOrdem,
                                               null);
      
      end loop;
    end if;
  
    --NOW I HAVE TO CHECK THE NODES CONNECTING TO NODE2
    if vnodo2 != pNodoAnterior then
      for nodo in nodos(vFID, vnodo2) loop
        vEAM2.extend();
        vEAM2(vEAM2.COUNT) := eam_trace_record(nodo.g3e_id,
                                               nodo.g3e_fid,
                                               nodo.g3e_fno,
                                               nodo.nodo1_id,
                                               nodo.nodo2_id,
                                               vActivo,
                                               vOrdem,
                                               null);
      
      end loop;
    end if;
  
    --Verificar si es una valvula de corte
    select count(1)
      into vCount
      from eam_config
     where descripcion = 'TRAMO'
       and valor = pFid;
    if vCount > 0 and vDatos.count > 1 then
      vStop := 1;
    else
      vStop := 0;
    end if;
  
    --Nodo1
    if vNodo1 != pNodoAnterior and vEAM1.COUNT > 0 and vStop = 0 then
    
      for i in vEAM1.FIRST .. vEAM1.LAST loop
      
        if vEAM1(i).g3e_fno = 14100 then
          select count(1)
            into vCount
            from gtub_prm_at
           where g3e_fid = vEAM1(i).g3e_fid
             and tipo = 'MATRIZ';
          if vCount = 0 then
            continue;
          end if;
        end if;
      
        vOrdem := vOrdem + 1;
      
        vResTem := EAM_TRACETRAMOS(vEAM1(i).g3e_fid,
                                   vNodo1,
                                   vActivo,
                                   vOrdem,
                                   vDatos);
      
        if vResTem.COUNT > 0 then
          for i in vResTem.FIRST .. vResTem.LAST loop
            vResult.Extend();
            vResult(vResult.COUNT) := vResTem(i);
          end loop;
        end if;
      
      end loop;
    end if;
  
    --Nodo2
    if vNodo2 != pNodoAnterior and vEAM2.COUNT > 0 and vStop = 0 then
    
      for i in vEAM2.FIRST .. vEAM2.LAST loop
      
        if vEAM2(i).g3e_fno = 14100 then
          select count(1)
            into vCount
            from gtub_prm_at
           where g3e_fid = vEAM2(i).g3e_fid
             and tipo = 'MATRIZ';
          if vCount = 0 then
            continue;
          end if;
        end if;
      
        vOrdem  := vOrdem + 1;
        vResTem := EAM_TRACETRAMOS(vEAM2(i).g3e_fid,
                                   vNodo2,
                                   vActivo,
                                   vOrdem,
                                   vDatos);
      
        if vResTem.COUNT > 0 then
          for i in vResTem.FIRST .. vResTem.LAST loop
            vResult.Extend();
            vResult(vResult.COUNT) := vResTem(i);
          end loop;
        end if;
      
      end loop;
    end if;
  
    vTipo := null;
    begin
      if vFno = 14100 then
        select tipo_nombre
          into vTipo
          from gtub_prm_at
         where g3e_fid = vFid
           and tipo = 'MATRIZ';
      end if;
    exception
      when others then
        vTipo := null;
    end;
  
    vResult.Extend();
    vResult(vResult.COUNT) := eam_trace_record(null,
                                               vFID,
                                               vFNO,
                                               vNodo1,
                                               vNodo2,
                                               pActivo,
                                               pOrdem,
                                               vTipo);
  
    return vResult;
  end;

  function EAM_TRACERAMALES(pFidInicial   IN NUMBER,
                            pCircuito     IN VARCHAR,
                            pNodoAnterior IN NUMBER,
                            pDatos        IN EAM_TRACE_TABLE DEFAULT EAM_TRACE_TABLE())
    return EAM_TRACE_TABLE as
  
    --HACE EL TRACE PARA CREAR LOS TRAMOS
    vEAM1   EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vEAM2   EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vNodo1  NUMBER(10);
    vNodo2  NUMBER(10);
    vFNO    NUMBER(5);
    vFID    NUMBER(10);
    vCount  NUMBER;
    vResult EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vResTem EAM_TRACE_TABLE := EAM_TRACE_TABLE();
    vDatos  EAM_TRACE_TABLE := pDatos;
  
    cursor nodos(vFid number, nodo number) is
      select *
        from cconectividad_g
       where g3e_fid <> vFid
         and (nodo1_id = nvl(nullif(nodo, 0), -1) or
             nodo2_id = nvl(nullif(nodo, 0), -1));
  
  begin
  
    --Verificar si el registro ya fue procesado y no tene run loop infinito
    select /* parallel */
     count(1)
      into vCount
      from table(vDatos)
     where g3e_fid = pFidInicial;
  
    if vCount > 0 then
      return vResult;
    else
      vDatos.extend();
      vDatos(vDatos.COUNT) := eam_trace_record(null,
                                               pFidInicial,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null,
                                               null);
    end if;
  
    --NOW WE NEED TO GET THE NODE1 AND NODE2 OF THE PROVIDED G3E_ID
    select nodo1_id, nodo2_id, g3e_fno, g3e_fid
      into vNodo1, vNodo2, vFNO, vFID
      from cconectividad_g
     where g3e_fid = pFidInicial;
  
    --NOW I HAVE TO CHECK THE NODES CONNECTING TO NODE1
    if vnodo1 != pNodoAnterior then
      for nodo in nodos(vFID, vnodo1) loop
        vEAM1.extend();
        vEAM1(vEAM1.COUNT) := eam_trace_record(nodo.g3e_id,
                                               nodo.g3e_fid,
                                               nodo.g3e_fno,
                                               nodo.nodo1_id,
                                               nodo.nodo2_id,
                                               0,
                                               0,
                                               null);
      
      end loop;
    end if;
  
    --NOW I HAVE TO CHECK THE NODES CONNECTING TO NODE2
    if vnodo2 != pNodoAnterior then
      for nodo in nodos(vFID, vnodo2) loop
        vEAM2.extend();
        vEAM2(vEAM2.COUNT) := eam_trace_record(nodo.g3e_id,
                                               nodo.g3e_fid,
                                               nodo.g3e_fno,
                                               nodo.nodo1_id,
                                               nodo.nodo2_id,
                                               0,
                                               0,
                                               null);
      
      end loop;
    end if;
  
    --Nodo1
    if vNodo1 != pNodoAnterior and vEAM1.COUNT > 0 then
    
      for i in vEAM1.FIRST .. vEAM1.LAST loop
      
        if vEAM1(i).g3e_fno = 14100 then
          select count(1)
            into vCount
            from gtub_prm_at
           where g3e_fid = vEAM1(i).g3e_fid
             and tipo = 'RAMAL'
             and tipo_nombre = pCircuito;
          if vCount = 0 then
            continue;
          end if;
        end if;
      
        if vEAM1(i)
         .g3e_fno not in
            (14100, 14200, 14400, 14100, 14000, 14300, 16200, 16300, 15600) then
          continue;
        end if;
      
        vResTem := EAM_TRACERAMALES(vEAM1(i).g3e_fid,
                                    pCircuito,
                                    vNodo1,
                                    vDatos);
      
        if vResTem.COUNT > 0 then
          for i in vResTem.FIRST .. vResTem.LAST loop
            vResult.Extend();
            vResult(vResult.COUNT) := vResTem(i);
          end loop;
        end if;
      
      end loop;
    end if;
  
    --Nodo2
    if vNodo2 != pNodoAnterior and vEAM2.COUNT > 0 then
    
      for i in vEAM2.FIRST .. vEAM2.LAST loop
      
        if vEAM2(i).g3e_fno = 14100 then
          select count(1)
            into vCount
            from gtub_prm_at
           where g3e_fid = vEAM2(i).g3e_fid
             and tipo = 'RAMAL'
             and tipo_nombre = pCircuito;
          if vCount = 0 then
            continue;
          end if;
        end if;
      
        if vEAM2(i)
         .g3e_fno not in
            (14100, 14200, 14400, 14100, 14000, 14300, 16200, 16300, 15600) then
          continue;
        end if;
      
        vResTem := EAM_TRACERAMALES(vEAM2(i).g3e_fid,
                                    pCircuito,
                                    vNodo2,
                                    vDatos);
      
        if vResTem.COUNT > 0 then
          for i in vResTem.FIRST .. vResTem.LAST loop
            vResult.Extend();
            vResult(vResult.COUNT) := vResTem(i);
          end loop;
        end if;
      
      end loop;
    end if;
  
    vResult.Extend();
    vResult(vResult.COUNT) := eam_trace_record(null,
                                               vFID,
                                               vFNO,
                                               vNodo1,
                                               vNodo2,
                                               0,
                                               0,
                                               null);
  
    return vResult;
  end;

  procedure EAM_TAXONOMIA is
  
    --Variables
    resTrace     eam_trace_table; --Guarda el resultado de los traces
    pDatos       eam_trace_table := eam_trace_table(); --Parametro para los traces no se quedaren en loop infinito
    pValvu       eam_trace_table := eam_trace_table(); --Guarda las valvula de seccionamento
    codigo       varchar2(50); --codigo del activo
    codigo_padre varchar2(50); --codigo del activo padre
    vCount       number; --auxiliar
    vTipoNodo    varchar2(50);
    vTramos      number; --cantidad de tramos
    vPerID       cpertenencia.G3E_ID%type; --guarda el id de la pertenencia
    vRamalFNO    number(5);
    vRamalFID    number(10);
    vRamalFecha  date;
    vFechaComun  date;
    vFechaEjec   date;
  
    --Configuraciones
    vClaseTramosMatriz            VARCHAR2(100);
    vClaseEstacionSeccionamiento  VARCHAR2(100);
    vClaseInstrumentacion         VARCHAR2(100);
    vClaseObraCivilSeccionamiento VARCHAR2(100);
    vClaseByPass                  VARCHAR2(100);
    vClaseObraCivilMatriz         VARCHAR2(100);
    vClaseRamal                   VARCHAR2(100);
    vClaseCircuito                VARCHAR2(100);
    vClaseTuberiaRamal            VARCHAR2(100);
    vClaseObraCivilRamal          VARCHAR2(100);
    vClaseArteria                 VARCHAR2(100);
    vClasePolivalvulaArteria      VARCHAR2(100);
    vClaseTuberiaArteria          VARCHAR2(100);
    vClaseObraCivilArteria        VARCHAR2(100);
    vClaseAnillo                  VARCHAR2(100);
    vClasePolivalvulaAnillo       VARCHAR2(100);
    vClaseTuberiaAnillo           VARCHAR2(100);
    vClaseObraCivilAnillo         VARCHAR2(100);
    vClaseUnidadRectificadora     VARCHAR2(100);
    vClaseRectificador            VARCHAR2(100);
    vClaseObraCivilRectificador   VARCHAR2(100);
    vClasePedestalMonitoreo       VARCHAR2(100);
    vClaseUnidadAislamiento       VARCHAR2(100);
    vClaseCeldaKirk               VARCHAR2(100);
    vClaseEstacionDerivacion      VARCHAR2(100);
    vClaseValvulaDerivacion       VARCHAR2(100);
    vClaseValvulaSeccionamiento   VARCHAR2(100);
    vClaseObraCivilDerivacion     VARCHAR2(100);
    vRegionLineaPrimaria          VARCHAR2(100);
  
    vLineaMatrizRedM          VARCHAR2(100);
    vRamalesRedM              VARCHAR2(100);
    vCeldasKirkRedM           VARCHAR2(100);
    vProteccionCatodiaRedM    VARCHAR2(100);
    vSistemasValvulasRedM     VARCHAR2(100);
    vLineaSecundariaRedM      VARCHAR2(100);
    vLineaMatrizRedRegA       VARCHAR2(100);
    vRamalesRedRegA           VARCHAR2(100);
    vCeldasKirkRedRegA        VARCHAR2(100);
    vProteccionCatodiaRedRegA VARCHAR2(100);
    vSistemasValvulasRedRegA  VARCHAR2(100);
    vLineaSecundariaRedRegA   VARCHAR2(100);
  
    --Linea Primaria -> Linea Matriz -> Obra Civil
    cursor lp_lm_oc is
      select protec.g3e_fid   fid_protec,
             protec.g3e_fno   fno_protec,
             tubp.g3e_fid     tub_fid,
             tubp.tipo_nombre nombre_ramal
        from cpertenencia protec
       inner join cpertenencia tub
          on tub.g3e_id = protec.G3E_OWNERID
       inner join gtub_prm_at tubp
          on tubp.g3e_fid = tub.g3e_fid
       where protec.g3e_fno = 15400
         and protec.G3E_OWNERID is not null
         and tubp.tipo = 'MATRIZ';
  
    --Linea Primaria -> Ramales -> Obra Civil
    cursor lp_rm_oc is
      select protec.g3e_fid   fid_protec,
             protec.g3e_fno   fno_protec,
             tubp.g3e_fid     tub_fid,
             tubp.tipo_nombre ramal
        from cpertenencia protec
       inner join cpertenencia tub
          on tub.g3e_id = protec.G3E_OWNERID
       inner join gtub_prm_at tubp
          on tubp.g3e_fid = tub.g3e_fid
       where protec.g3e_fno = 15400
         and protec.G3E_OWNERID is not null
         and tubp.tipo = 'RAMAL'
       order by tubp.tipo_nombre;
  
    --Linear Primaria, Proteccion Catódica
    cursor lp_proteccion is
      select protec.g3e_fid, protec.g3e_fno, protec.tipo_proteccion_activa
        from GPRO_ACT_AT protec
       inner join ccomun cm
          on cm.g3e_fid = protec.g3e_fid
         and cm.g3e_fno = protec.g3e_fno
       where cm.estado != 'RETIRADO';
  
    --Linea Primaria, Unidad de Aislamiento
    cursor lp_uni_aisla is
      select nd.g3e_fid, nd.g3e_fno, nd.tipo_nodo
        from GNOD_PRM_AT nd
       inner join ccomun cm
          on cm.g3e_fid = nd.g3e_fid
         and cm.g3e_fno = nd.g3e_fno
       where nd.tipo_nodo in ('JUNTA MONOLITICA', 'BRIDA AISLAMIENTO')
         and cm.estado != 'RETIRADO';
  
    --Linea Primaria, Celda Kirk
    cursor lp_celda is
      select cd.g3e_fid, cd.g3e_fno
        from GCEL_KIR_AT cd
       inner join ccomun cm
          on cm.g3e_fid = cd.g3e_fid
         and cm.g3e_fno = cd.g3e_fno
       where cm.estado != 'RETIRADO';
  
    --Circuitos
    cursor circuitos is
      select min(cn.g3e_fid) g3e_fid,
             min(cn.g3e_fno) g3e_fno,
             cn.nombre_circuito
        from cconectividad_g cn
       inner join ccomun cm
          on cm.g3e_fid = cn.g3e_fid
         and cm.g3e_fno = cn.G3E_FNO
       where cn.g3e_fno = 14400
         and cm.ESTADO != 'RETIRADO'
       group by cn.NOMBRE_CIRCUITO
      having count(1) = 1;
  
    --Linea Secundaria -> Arteria -> Obra Civil
    cursor ls_ar_oc(pCircuito VARCHAR2) is
      select conn.g3e_fno         fno_tuberia,
             conn.g3e_fid         fid_tuberia,
             per2.g3e_fno         fno_protec,
             per2.g3e_fid         fid_protec,
             conn.nombre_circuito circuito
        from cconectividad_g conn
       inner join cpertenencia per1
          on per1.g3e_fid = conn.g3e_fid
       inner join cpertenencia per2
          on per2.g3e_ownerid = per1.g3e_id
       where conn.g3e_fno = 14600
         and per2.g3e_fno = 15400
         and conn.nombre_circuito = pCircuito;
  
    --Linea Secundaria -> Anillo -> Obra Civil
    cursor ls_an_oc(pCircuito VARCHAR2) is
      select conn.g3e_fno         fno_tuberia,
             conn.g3e_fid         fid_tuberia,
             per2.g3e_fno         fno_protec,
             per2.g3e_fid         fid_protec,
             conn.nombre_circuito circuito,
             conn.codigo_valvula  codigo_valvula
        from cconectividad_g conn
       inner join cpertenencia per1
          on per1.g3e_fid = conn.g3e_fid
       inner join cpertenencia per2
          on per2.g3e_ownerid = per1.g3e_id
       where conn.g3e_fno = 15000
         and per2.g3e_fno = 15400
         and conn.nombre_circuito = pCircuito;
  
  begin
  
    delete from eam_activos_temp;
    commit;
  
    delete from eam_errors;
    commit;
  
    delete from eam_ubicacion_temp;
    commit;
  
    --Carga Configuración
    select valor
      into vClaseTramosMatriz
      from eam_config
     where descripcion = 'ClaseTramosMatriz';
    select valor
      into vClaseEstacionSeccionamiento
      from eam_config
     where descripcion = 'ClaseEstacionSeccionamiento';
    select valor
      into vClaseInstrumentacion
      from eam_config
     where descripcion = 'ClaseInstrumentacion';
    select valor
      into vClaseObraCivilSeccionamiento
      from eam_config
     where descripcion = 'ClaseObraCivilSeccionamiento';
    select valor
      into vClaseByPass
      from eam_config
     where descripcion = 'ClaseByPass';
    select valor
      into vClaseObraCivilMatriz
      from eam_config
     where descripcion = 'ClaseObraCivilMatriz';
    select valor
      into vClaseRamal
      from eam_config
     where descripcion = 'ClaseRamal';
    select valor
      into vClaseCircuito
      from eam_config
     where descripcion = 'ClaseCircuito';
    select valor
      into vClaseTuberiaRamal
      from eam_config
     where descripcion = 'ClaseTuberiaRamal';
    select valor
      into vClaseObraCivilRamal
      from eam_config
     where descripcion = 'ClaseObraCivilRamal';
    select valor
      into vClaseArteria
      from eam_config
     where descripcion = 'ClaseArteria';
    select valor
      into vClasePolivalvulaArteria
      from eam_config
     where descripcion = 'ClasePolivalvulaArteria';
    select valor
      into vClaseTuberiaArteria
      from eam_config
     where descripcion = 'ClaseTuberiaArteria';
    select valor
      into vClaseObraCivilArteria
      from eam_config
     where descripcion = 'ClaseObraCivilArteria';
    select valor
      into vClaseAnillo
      from eam_config
     where descripcion = 'ClaseAnillo';
    select valor
      into vClasePolivalvulaAnillo
      from eam_config
     where descripcion = 'ClasePolivalvulaAnillo';
    select valor
      into vClaseTuberiaAnillo
      from eam_config
     where descripcion = 'ClaseTuberiaAnillo';
    select valor
      into vClaseObraCivilAnillo
      from eam_config
     where descripcion = 'ClaseObraCivilAnillo';
    select valor
      into vClaseUnidadRectificadora
      from eam_config
     where descripcion = 'ClaseUnidadRectificadora';
    select valor
      into vClaseRectificador
      from eam_config
     where descripcion = 'ClaseRectificador';
    select valor
      into vClaseObraCivilRectificador
      from eam_config
     where descripcion = 'ClaseObraCivilRectificador';
    select valor
      into vClasePedestalMonitoreo
      from eam_config
     where descripcion = 'ClasePedestalMonitoreo';
    select valor
      into vClaseUnidadAislamiento
      from eam_config
     where descripcion = 'ClaseUnidadAislamiento';
    select valor
      into vClaseCeldaKirk
      from eam_config
     where descripcion = 'ClaseCeldaKirk';
    select valor
      into vClaseEstacionDerivacion
      from eam_config
     where descripcion = 'ClaseEstacionDerivacion';
    select valor
      into vClaseValvulaDerivacion
      from eam_config
     where descripcion = 'ClaseValvulaDerivacion';
    select valor
      into vClaseObraCivilDerivacion
      from eam_config
     where descripcion = 'ClaseObraCivilDerivacion';
    select valor
      into vClaseValvulaSeccionamiento
      from eam_config
     where descripcion = 'ClaseValvulaSeccionamiento';
  
    select valor
      into vLineaMatrizRedM
      from eam_config
     where descripcion = 'LineaMatrizRedMetropolitana';
    select valor
      into vRamalesRedM
      from eam_config
     where descripcion = 'RamalesRedMetropolitana';
    select valor
      into vCeldasKirkRedM
      from eam_config
     where descripcion = 'CeldasKirkRedMetropolitana';
    select valor
      into vProteccionCatodiaRedM
      from eam_config
     where descripcion = 'ProteccionCatodiaRedMetropolitana';
    select valor
      into vSistemasValvulasRedM
      from eam_config
     where descripcion = 'SistemasValvulasRedMetropolitana';
    select valor
      into vLineaSecundariaRedM
      from eam_config
     where descripcion = 'LineaSecundariaRedMetropolitana';
    select valor
      into vLineaMatrizRedRegA
      from eam_config
     where descripcion = 'LineaMatrizRedRegionAntioquia';
    select valor
      into vRamalesRedRegA
      from eam_config
     where descripcion = 'RamalesRedRegionAntioquia';
    select valor
      into vCeldasKirkRedRegA
      from eam_config
     where descripcion = 'CeldasKirkRedRegionAntioquia';
    select valor
      into vProteccionCatodiaRedRegA
      from eam_config
     where descripcion = 'ProteccionCatodiaRedRegionAntioquia';
    select valor
      into vSistemasValvulasRedRegA
      from eam_config
     where descripcion = 'SistemasValvulasRedRegionAntioquia';
    select valor
      into vLineaSecundariaRedRegA
      from eam_config
     where descripcion = 'LineaSecundariaRedRegionAntioquia';
    select valor
      into vRegionLineaPrimaria
      from eam_config
     where descripcion = 'RegionLineaPrimaria';
  
    select count(distinct(tipo_nombre))
      into vTramos
      from gtub_prm_at
     where tipo = 'MATRIZ';
  
    vTramos := vTramos - 1;
  
    --Linea Matriz, Tramos con agrupación y Sistemas de Valvulas de Seccionamiento
    for tramo in 0 .. vTramos loop
    
      --Para cada tramos buscar las tuberias
      resTrace := eam_tracetramoespecifico(tramo);
    
      for elTrace in (select t.* from table(resTrace) t order by t.ordem asc) loop
      
        if elTrace.g3e_fno = 14100 then
          --Tuberia Primaria
          begin
            select tipo_nombre
              into codigo
              from gtub_prm_at
             where tipo = 'MATRIZ'
               and g3e_fid = elTrace.g3e_fid;
          
            insert into eam_activos_temp
            values
              ('MATRIZ',
               vRegionLineaPrimaria,
               vClaseTramosMatriz,
               elTrace.g3e_fid,
               elTrace.g3e_fno,
               'TRAM-' || elTrace.grupo,
               case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
               vLineaMatrizRedM when 0 then vLineaMatrizRedRegA end, --vUbicacionMatriz,
               6,
               null,
               null,
               null,
               elTrace.grupo,
               elTrace.ordem,
               sysdate);
            commit;
          exception
            when others then
              continue;
          end;
        elsif elTrace.g3e_fno = 14200 then
          --Valvula Primaria
        
          --Mirar sy la valvula ya fue caculada
          select count(1)
            into vCount
            from table(pValvu) v
           where v.g3e_fid = elTrace.g3e_fid
             and v.g3e_fno = elTrace.g3e_fno;
        
          if vCount > 0 then
            continue;
          end if;
        
          pValvu.extend();
          pValvu(pValvu.COUNT) := eam_trace_record(null,
                                                   elTrace.g3e_fid,
                                                   elTrace.g3e_fno,
                                                   null,
                                                   null,
                                                   null,
                                                   null,
                                                   null);
        
          select codigo_valvula
            into codigo
            from cconectividad_g
           where g3e_fid = elTrace.g3e_fid
             and g3e_fno = elTrace.g3e_fno;
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClaseEstacionSeccionamiento,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             'EVS-' || codigo,
             case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
             vSistemasValvulasRedM when 0 then vSistemasValvulasRedRegA end, --vUbicacionEstSeccionamiento,
             6,
             null,
             null,
             null,
             null,
             null,
             sysdate);
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClaseInstrumentacion,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             null,
             case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
             vSistemasValvulasRedM when 0 then vSistemasValvulasRedRegA end, --vUbicacionEstSeccionamiento,
             7,
             elTrace.g3e_fid,
             'EVS-' || codigo,
             null,
             null,
             null,
             sysdate);
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClaseObraCivilSeccionamiento,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             null,
             case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
             vSistemasValvulasRedM when 0 then vSistemasValvulasRedRegA end, --vUbicacionEstSeccionamiento,
             7,
             elTrace.g3e_fid,
             'EVS-' || codigo,
             null,
             null,
             null,
             sysdate);
          commit;
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClaseValvulaSeccionamiento,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             null,
             case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
             vSistemasValvulasRedM when 0 then vSistemasValvulasRedRegA end, --vUbicacionEstSeccionamiento,
             7,
             elTrace.g3e_fid,
             'EVS-' || codigo,
             null,
             null,
             null,
             sysdate);
          commit;
        
          --por ultimo de las valvulas de seccionamento hay que buscar por las ByPass
          begin
            select g3e_id
              into vPerId
              from cpertenencia
             where g3e_fid = elTrace.g3e_fid
               and g3e_fno = elTrace.g3e_fno;
            codigo_padre := codigo;
            for bypass in (select g3e_fid, g3e_fno
                             from cpertenencia
                            where g3e_ownerid = vPerID
                              and g3e_fno = 14200) loop
            
              select codigo_valvula
                into codigo
                from cconectividad_g
               where g3e_fid = bypass.g3e_fid
                 and g3e_fno = 14200;
            
              insert into eam_activos_temp
              values
                ('MATRIZ',
                 vRegionLineaPrimaria,
                 vClaseByPass,
                 bypass.g3e_fid,
                 bypass.g3e_fno,
                 null,
                 case EAM_ESMETROPOLITANA(bypass.g3e_fid, bypass.g3e_fno) when 1 then
                 vSistemasValvulasRedM when 0 then vSistemasValvulasRedRegA end, --vUbicacionEstSeccionamiento,
                 7,
                 elTrace.g3e_fid,
                 'EVS-' || codigo_padre,
                 null,
                 null,
                 null,
                 sysdate);
              commit;
            
            end loop;
          exception
            when others then
              continue;
          end;
        
        end if;
      
      end loop;
    
    end loop;
  
    --Mirar si hay activos (tramos agrupados) por error de catastro
  
    insert into eam_errors
      select 'TRAMO',
             g3e_fid,
             g3e_fno,
             sysdate,
             'Hay bifurcacion en el tramo'
        from eam_activos_temp
       where activo in
             (select distinct activo
                from eam_activos_temp
               where (activo, ordem) in
                     (select a1.activo, a1.ordem
                        from eam_activos_temp a1
                       where a1.clase = 'TRAMO' having count(a1.ordem) >= 2
                       group by a1.activo, a1.ordem));
    commit;
  
    delete from eam_activos_temp
     where activo in
           (select distinct activo
              from eam_activos_temp
             where (activo, ordem) in
                   (select a1.activo, a1.ordem
                      from eam_activos_temp a1
                     where a1.clase = 'TRAMO' having count(a1.ordem) >= 2
                     group by a1.activo, a1.ordem));
    commit;
  
    --Linea Matriz, Obra Civil
    for clp_lm_oc in lp_lm_oc loop
      insert into eam_activos_temp
      values
        ('MATRIZ',
         vRegionLineaPrimaria,
         vClaseObraCivilMatriz,
         clp_lm_oc.fid_protec,
         clp_lm_oc.fno_protec,
         null,
         case
          EAM_ESMETROPOLITANA(clp_lm_oc.fid_protec, clp_lm_oc.fno_protec)
           when 1 then
            vLineaMatrizRedM
           when 0 then
            vLineaMatrizRedRegA
         end, --vUbicacionMatriz,
         6,
         clp_lm_oc.tub_fid,
         null,
         null,
         0,
         0,
         sysdate);
    end loop;
    commit;
  
    ---Ramales
    for cramal in (select min(g3e_fid) fid_tub, tipo_nombre
                     from gtub_prm_at
                    where tipo = 'RAMAL'
                    group by tipo_nombre
                    order by tipo_nombre) loop
    
      pDatos := eam_trace_table();
      --Para cada tramos buscar las tuberias
      resTrace := eam_traceramales(cramal.fid_tub,
                                   cramal.tipo_nombre,
                                   0,
                                   pdatos);
    
      vRamalFNO   := 0;
      vRamalFID   := 0;
      vRamalFecha := sysdate;
      codigo      := null;
    
      for elTrace in (select t.*
                        from table(resTrace) t
                       order by case
                                  when t.g3e_fno = 14400 then
                                   1 --Reguladores
                                  when t.g3e_fno = 16300 then
                                   2 --Clientes
                                  when t.g3e_fno = 15600 then
                                   3 --Estación de Servicio
                                  when t.g3e_fno = 14000 then
                                   4 --Nodo Primario
                                  when t.g3e_fno = 14100 then
                                   5 --Tuberia Primaria
                                  when t.g3e_fno = 14200 then
                                   6 --Valvulas
                                  else
                                   7 --Otros
                                end) loop
      
        if elTrace.g3e_fno = 14400 then
          --Regulador
          begin
            select fecha_instalacion
              into vFechaComun
              from ccomun
             where g3e_fno = elTrace.g3e_fno
               and g3e_fid = elTrace.g3e_fid;
          
            if vFechaComun < vRamalFecha then
              vRamalFNO   := elTrace.g3e_fno;
              vRamalFID   := elTrace.g3e_fid;
              vRamalFecha := vFechaComun;
            end if;
          exception
            when others then
              insert into eam_errors
              values
                ('RAMAL ' || cRamal.Tipo_Nombre,
                 elTrace.g3e_fid,
                 elTrace.g3e_fno,
                 sysdate,
                 'El elemento no tiene Fecha de Instalación');
              commit;
          end;
        
        end if;
      
        if elTrace.g3e_fno = 16300 then
          --Clientes
        
          if vRamalFno = 14400 then
            continue;
          else
            begin
              select fecha_instalacion
                into vFechaComun
                from ccomun
               where g3e_fno = elTrace.g3e_fno
                 and g3e_fid = elTrace.g3e_fid;
            
              if vFechaComun < vRamalFecha then
                vRamalFNO   := elTrace.g3e_fno;
                vRamalFID   := elTrace.g3e_fid;
                vRamalFecha := vFechaComun;
              end if;
            exception
              when others then
                insert into eam_errors
                values
                  ('RAMAL ' || cRamal.Tipo_Nombre,
                   elTrace.g3e_fid,
                   elTrace.g3e_fno,
                   sysdate,
                   'El elemento no tiene Fecha de Instalación');
                commit;
            end;
          end if;
        
        end if;
      
        if elTrace.g3e_fno = 15600 then
          --Estación de Servicio
        
          if vRamalFno = 14400 then
            continue;
          else
            begin
              select fecha_instalacion
                into vFechaComun
                from ccomun
               where g3e_fno = elTrace.g3e_fno
                 and g3e_fid = elTrace.g3e_fid;
            
              if vFechaComun < vRamalFecha then
                vRamalFNO   := elTrace.g3e_fno;
                vRamalFID   := elTrace.g3e_fid;
                vRamalFecha := vFechaComun;
              end if;
            
            exception
              when others then
                insert into eam_errors
                values
                  ('RAMAL ' || cRamal.Tipo_Nombre,
                   elTrace.g3e_fid,
                   elTrace.g3e_fno,
                   sysdate,
                   'El elemento no tiene Fecha de Instalación');
                commit;
            end;
          end if;
        
        end if;
      
        if elTrace.g3e_fno = 14000 then
          --Nodo Primario
        
          if vRamalFno = 0 then
            --No he encontrado ningun otro elemento padre del Ramal
            select tipo_nodo
              into vTipoNodo
              from GNOD_PRM_AT
             where g3e_fid = elTrace.g3e_fid
               and g3e_fno = elTrace.g3e_fno;
          
            if vTipoNodo = 'TAPON' then
              begin
                select fecha_instalacion
                  into vFechaComun
                  from ccomun
                 where g3e_fno = elTrace.g3e_fno
                   and g3e_fid = elTrace.g3e_fid;
              
                vRamalFNO   := elTrace.g3e_fno;
                vRamalFID   := elTrace.g3e_fid;
                vRamalFecha := vFechaComun;
              
              exception
                when others then
                  insert into eam_errors
                  values
                    ('RAMAL ' || cRamal.Tipo_Nombre,
                     elTrace.g3e_fid,
                     elTrace.g3e_fno,
                     sysdate,
                     'El elemento no tiene Fecha de Instalación');
                  commit;
              end;
            
            end if;
          
          end if;
        end if;
      
        if elTrace.g3e_fno = 14200 then
          --Valvula
        
          --Linea Primaria, Estación Valvula Derivación
          select codigo_valvula
            into codigo
            from cconectividad_g
           where g3e_fid = elTrace.g3e_fid
             and g3e_fno = elTrace.g3e_fno;
        
          insert into eam_activos_temp
          values
            ('RAMAL',
             vRegionLineaPrimaria,
             vClaseEstacionDerivacion,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             'EVD-' || codigo,
             case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
             vSistemasValvulasRedM when 0 then vSistemasValvulasRedRegA end,
             6,
             null,
             null,
             null,
             0,
             0,
             sysdate);
        
          -- Linea Primaria, Estación Valvula Derivación, Valvula Derivacion
          insert into eam_activos_temp
          values
            ('RAMAL',
             vRegionLineaPrimaria,
             vClaseValvulaDerivacion,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             null,
             case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
             vSistemasValvulasRedM when 0 then vSistemasValvulasRedRegA end,
             7,
             elTrace.g3e_fid,
             'EVD-' || codigo,
             null,
             0,
             0,
             sysdate);
        
          --Linea Primaria, Estación Valvula Derivación, Obra Civil Derivacion
          insert into eam_activos_temp
          values
            ('RAMAL',
             vRegionLineaPrimaria,
             vClaseObraCivilDerivacion,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             null,
             case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
             vSistemasValvulasRedM when 0 then vSistemasValvulasRedRegA end,
             7,
             elTrace.g3e_fid,
             'EVD-' || codigo,
             null,
             0,
             0,
             sysdate);
          commit;
        end if;
      
        if elTrace.g3e_fno = 14100 then
          --Tuberia Primaria
          if codigo is null then
            --Hay que calcular el codigo del activo padre del ramal
          
            if vRamalFid = 0 then
              insert into eam_errors
              values
                ('RAMAL ' || cRamal.Tipo_Nombre,
                 0,
                 0,
                 sysdate,
                 'El ramal to tiene elemento padre');
              commit;
              exit;
            end if;
          
            select 'RAM-' || ora_hash(cRamal.tipo_nombre, 88888888)
              into codigo
              from dual;
          
            insert into eam_activos_temp
            values
              ('RAMAL',
               cRamal.tipo_nombre,
               vClaseRamal,
               vRamalFid,
               vRamalFno,
               codigo,
               case EAM_ESMETROPOLITANA(vRamalFid, vRamalFno) when 1 then
               vRamalesRedM when 0 then vRamalesRedRegA end, --vUbicacionRamal,
               6,
               null,
               null,
               null,
               0,
               0,
               sysdate);
            commit;
          end if;
        
          insert into eam_activos_temp
          values
            ('RAMAL',
             cRamal.Tipo_Nombre,
             vClaseTuberiaRamal,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             null,
             case EAM_ESMETROPOLITANA(elTrace.g3e_fid, elTrace.g3e_fno) when 1 then
             vRamalesRedM when 0 then vRamalesRedRegA end, --vUbicacionRamal,
             7,
             vRamalFid,
             codigo,
             null,
             0,
             0,
             sysdate);
          commit;
        
        end if;
      
      end loop;
    end loop;
  
    --Ramal, Obra Civil
    for clp_rm_oc in lp_rm_oc loop
    
      select count(1)
        into vCount
        from eam_activos_temp
       where codigo_activo = 'RAM-' || ora_hash(clp_rm_oc.ramal, 88888888)
         and clase = vClaseRamal;
    
      if vCount = 0 then
        insert into eam_errors
        values
          (clp_rm_oc.ramal,
           clp_rm_oc.fid_protec,
           clp_rm_oc.fno_protec,
           sysdate,
           'No se encontro el padre del ramal');
        commit;
        continue;
      end if;
    
      insert into eam_activos_temp
      values
        ('RAMAL',
         clp_rm_oc.ramal,
         vClaseObraCivilRamal,
         clp_rm_oc.fid_protec,
         clp_rm_oc.fno_protec,
         null,
         case
         EAM_ESMETROPOLITANA(clp_rm_oc.fid_protec, clp_rm_oc.fno_protec) when 1 then
         vRamalesRedM when 0 then vRamalesRedRegA end, --vUbicacionRamal,
         7,
         clp_rm_oc.tub_fid,
         'RAM-' || ora_hash(clp_rm_oc.ramal, 88888888),
         null,
         0,
         0,
         sysdate);
    end loop;
    commit;
  
    --Linea Primaria, Protección Catódica
    for elp_proteccion in lp_proteccion loop
      case elp_proteccion.tipo_proteccion_activa
        when 'RECTIFICADOR DE CORRIENTE' then
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClaseUnidadRectificadora,
             elp_proteccion.g3e_fid,
             elp_proteccion.g3e_fno,
             'URT-' || elp_proteccion.g3e_fid,
             case EAM_ESMETROPOLITANA(elp_proteccion.g3e_fid,
                                  elp_proteccion.g3e_fno)
               when 1 then
                vProteccionCatodiaRedM
               when 0 then
                vProteccionCatodiaRedRegA
             end,
             6,
             null,
             null,
             null,
             0,
             0,
             sysdate);
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClaseRectificador,
             elp_proteccion.g3e_fid,
             elp_proteccion.g3e_fno,
             null,
             case EAM_ESMETROPOLITANA(elp_proteccion.g3e_fid,
                                  elp_proteccion.g3e_fno)
               when 1 then
                vProteccionCatodiaRedM
               when 0 then
                vProteccionCatodiaRedRegA
             end,
             7,
             elp_proteccion.g3e_fid,
             'URT-' || elp_proteccion.g3e_fid,
             null,
             0,
             0,
             sysdate);
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClaseObraCivilRectificador,
             elp_proteccion.g3e_fid,
             elp_proteccion.g3e_fno,
             null,
             case EAM_ESMETROPOLITANA(elp_proteccion.g3e_fid,
                                 elp_proteccion.g3e_fno) when 1 then
             vProteccionCatodiaRedM when 0 then vProteccionCatodiaRedRegA end,
             7,
             elp_proteccion.g3e_fid,
             'URT-' || elp_proteccion.g3e_fid,
             null,
             0,
             0,
             sysdate);
          commit;
        when 'PEDESTAL DE MONITOREO TIPO 2' then
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClasePedestalMonitoreo,
             elp_proteccion.g3e_fid,
             elp_proteccion.g3e_fno,
             'PDM-' || elp_proteccion.g3e_fid,
             case EAM_ESMETROPOLITANA(elp_proteccion.g3e_fid,
                                  elp_proteccion.g3e_fno)
               when 1 then
                vProteccionCatodiaRedM
               when 0 then
                vProteccionCatodiaRedRegA
             end,
             6,
             null,
             null,
             null,
             0,
             0,
             sysdate);
          commit;
        
        when 'PEDESTAL DE MONITOREO TIPO 4' then
        
          insert into eam_activos_temp
          values
            ('MATRIZ',
             vRegionLineaPrimaria,
             vClasePedestalMonitoreo,
             elp_proteccion.g3e_fid,
             elp_proteccion.g3e_fno,
             'PDM-' || elp_proteccion.g3e_fid,
             case EAM_ESMETROPOLITANA(elp_proteccion.g3e_fid,
                                  elp_proteccion.g3e_fno)
               when 1 then
                vProteccionCatodiaRedM
               when 0 then
                vProteccionCatodiaRedRegA
             end,
             6,
             null,
             null,
             null,
             0,
             0,
             sysdate);
          commit;
      end case;
    
    end loop;
  
    --Linea Primaria, Unidad de Aislamiento
    for elp_uni_aisla in lp_uni_aisla loop
    
      insert into eam_activos_temp
      values
        ('MATRIZ',
         vRegionLineaPrimaria,
         vClaseUnidadAislamiento,
         elp_uni_aisla.g3e_fid,
         elp_uni_aisla.g3e_fno,
         'UAI-' || elp_uni_aisla.g3e_fid,
         case
          EAM_ESMETROPOLITANA(elp_uni_aisla.g3e_fid, elp_uni_aisla.g3e_fno)
           when 1 then
            vProteccionCatodiaRedM
           when 0 then
            vProteccionCatodiaRedRegA
         end,
         6,
         null,
         null,
         null,
         0,
         0,
         sysdate);
      commit;
    end loop;
  
    --Linea Primaria, Celda Kirk
    for elp_celda in lp_celda loop
    
      insert into eam_activos_temp
      values
        ('MATRIZ',
         vRegionLineaPrimaria,
         vClaseCeldaKirk,
         elp_celda.g3e_fid,
         elp_celda.g3e_fno,
         null,
         case EAM_ESMETROPOLITANA(elp_celda.g3e_fid, elp_celda.g3e_fno)
           when 1 then
            vCeldasKirkRedM
           when 0 then
            vCeldasKirkRedRegA
         end,
         6,
         null,
         null,
         null,
         0,
         0,
         sysdate);
      commit;
    end loop;
  
    -- Circuitos con más de un regulador
    insert into eam_errors
      select cn.nombre_circuito,
             cn.g3e_fid,
             cn.g3e_fno,
             sysdate,
             'El Circuito tiene más de uno regulador'
        from cconectividad_g cn
       inner join ccomun cm
          on cm.g3e_fid = cn.g3e_fid
         and cm.g3e_fno = cn.G3E_FNO
       where cn.g3e_fno = 14400
         and cm.ESTADO != 'RETIRADO'
         and cn.NOMBRE_CIRCUITO in (
                                    
                                    select cn.nombre_circuito
                                      from cconectividad_g cn
                                     inner join ccomun cm
                                        on cm.g3e_fid = cn.g3e_fid
                                       and cm.g3e_fno = cn.G3E_FNO
                                     where cn.g3e_fno = 14400
                                       and cm.ESTADO != 'RETIRADO'
                                     group by cn.NOMBRE_CIRCUITO
                                    having count(1) > 1);
    commit;
  
    --Circuitos
    for circuito in circuitos loop
      insert into eam_ubicacion_temp
      values
        (vClaseCircuito,
         circuito.g3e_fid,
         circuito.g3e_fno,
         ora_hash(circuito.nombre_circuito, 99999999),
         case EAM_ESMETROPOLITANA(circuito.g3e_fid, circuito.g3e_fno)
           when 1 then
            'CIV-' || ora_hash(circuito.nombre_circuito, 99999999)
           when 0 then
            'CIR-' || ora_hash(circuito.nombre_circuito, 99999999)
         end,
         5,
         case EAM_ESMETROPOLITANA(circuito.g3e_fid, circuito.g3e_fno)
           when 1 then
            vLineaSecundariaRedM
           when 0 then
            vLineaSecundariaRedRegA
         end,
         'CIRCUITO ' || circuito.nombre_circuito,
         sysdate);
    end loop;
  
    --Linea Secundaria, Activos
    for circuito in (select * from eam_ubicacion_temp) loop
    
      --Arteria
      insert into eam_activos_temp
      values
        ('CIRCUITO',
         substr(circuito.descripcion, 10),
         vClaseArteria,
         circuito.g3e_fid,
         circuito.g3e_fno,
         'ART-' || circuito.codigo,
         circuito.codigo_ubicacion,
         6,
         circuito.g3e_fid,
         null,
         null,
         0,
         0,
         sysdate);
    
      --Polivalvula Arteria
      for activo in (select g3e_fid, g3e_fno
                       from cconectividad_g
                      where g3e_fno = 14700
                        and nombre_circuito =
                            substr(circuito.descripcion, 10)) loop
        insert into eam_activos_temp
        values
          ('CIRCUITO',
           substr(circuito.descripcion, 10),
           vClasePolivalvulaArteria,
           activo.g3e_fid,
           activo.g3e_fno,
           null,
           circuito.codigo_ubicacion,
           7,
           circuito.g3e_fid,
           'ART-' || circuito.codigo,
           null,
           0,
           0,
           sysdate);
      end loop;
      commit;
    
      --Tuberia Arteria
      for activo in (select g3e_fid, g3e_fno
                       from cconectividad_g
                      where g3e_fno = 14600
                        and nombre_circuito =
                            substr(circuito.descripcion, 10)) loop
        insert into eam_activos_temp
        values
          ('CIRCUITO',
           substr(circuito.descripcion, 10),
           vClaseTuberiaArteria,
           activo.g3e_fid,
           activo.g3e_fno,
           null,
           circuito.codigo_ubicacion,
           7,
           circuito.g3e_fid,
           'ART-' || circuito.codigo,
           null,
           0,
           0,
           sysdate);
      end loop;
      commit;
    
      --Obra Civil Arteria
      for activo in ls_ar_oc(substr(circuito.descripcion, 10)) loop
        insert into eam_activos_temp
        values
          ('CIRCUITO',
           substr(circuito.descripcion, 10),
           vClaseObraCivilArteria,
           activo.fid_protec,
           activo.fno_protec,
           null,
           circuito.codigo_ubicacion,
           7,
           activo.fid_tuberia,
           'ART-' || circuito.codigo,
           null,
           0,
           0,
           sysdate);
      
      end loop;
      commit;
    
      --Anillo y Polivalvula Anillo
      for activo in (select g3e_fid, g3e_fno, codigo_valvula
                       from cconectividad_g
                      where g3e_fno = 15100
                        and nombre_circuito =
                            substr(circuito.descripcion, 10)) loop
        insert into eam_activos_temp
        values
          ('CIRCUITO',
           substr(circuito.descripcion, 10),
           vClaseAnillo,
           activo.g3e_fid,
           activo.g3e_fno,
           'ANI-' || activo.codigo_valvula,
           circuito.codigo_ubicacion,
           6,
           circuito.g3e_fid,
           null,
           null,
           0,
           0,
           sysdate);
      
        insert into eam_activos_temp
        values
          ('CIRCUITO',
           substr(circuito.descripcion, 10),
           vClasePolivalvulaAnillo,
           activo.g3e_fid,
           activo.g3e_fno,
           null,
           circuito.codigo_ubicacion,
           7,
           circuito.g3e_fid,
           'ANI-' || activo.codigo_valvula,
           null,
           0,
           0,
           sysdate);
      end loop;
      commit;
    
      --Tuberia Anillo
    
      --Tuberias que tienen un codigo_valvula que no pertenence a ninguna valvula
      insert into eam_errors
        select substr(circuito.descripcion, 10),
               g3e_fid,
               g3e_fno,
               sysdate,
               'No se encontro una valvula con el mismo codigo_valvula'
          from cconectividad_g
         where g3e_fno = 15000
           and nombre_circuito = substr(circuito.descripcion, 10)
           and codigo_valvula not in
               (select distinct codigo_valvula
                  from cconectividad_g
                 where g3e_fno = 15100);
    
      insert into eam_errors
        select substr(circuito.descripcion, 10),
               g3e_fid,
               g3e_fno,
               sysdate,
               'La valvula padre pertence a otro dicruito'
          from cconectividad_g
         where g3e_fno = 15000
           and nombre_circuito = substr(circuito.descripcion, 10)
           and codigo_valvula in
               (select distinct codigo_valvula
                  from cconectividad_g
                 where g3e_fno = 15100
                   and nombre_circuito != substr(circuito.descripcion, 10));
      commit;
    
      for activo in (select g3e_fid, g3e_fno, codigo_valvula
                       from cconectividad_g
                      where g3e_fno = 15000
                        and nombre_circuito =
                            substr(circuito.descripcion, 10)
                        and codigo_valvula in
                            (select distinct codigo_valvula
                               from cconectividad_g
                              where g3e_fno = 15100
                                and nombre_circuito =
                                    substr(circuito.descripcion, 10))) loop
      
        insert into eam_activos_temp
        values
          ('CIRCUITO',
           substr(circuito.descripcion, 10),
           vClaseTuberiaAnillo,
           activo.g3e_fid,
           activo.g3e_fno,
           null,
           circuito.codigo_ubicacion,
           7,
           circuito.g3e_fid,
           'ANI-' || activo.codigo_valvula,
           null,
           0,
           0,
           sysdate);
      end loop;
      commit;
    
      --Obra Civil Anillo
      for activo in ls_an_oc(substr(circuito.descripcion, 10)) loop
      
        select count(1)
          into vCount
          from cconectividad_g
         where codigo_valvula = activo.codigo_valvula
           and g3e_fno = 15100;
      
        if vCount = 0 then
          insert into eam_errors
          values
            (substr(circuito.descripcion, 10),
             activo.fid_protec,
             activo.fno_protec,
             sysdate,
             'No se encontro una valvula con el mismo codigo_valvula');
          commit;
          continue;
        end if;
      
        insert into eam_activos_temp
        values
          ('CIRCUITO',
           substr(circuito.descripcion, 10),
           vClaseObraCivilAnillo,
           activo.fid_protec,
           activo.fno_protec,
           null,
           circuito.codigo_ubicacion,
           7,
           activo.fid_tuberia,
           'ANI-' || activo.codigo_valvula,
           null,
           0,
           0,
           sysdate);
      
      end loop;
      commit;
    
    end loop;
  
    select sysdate into vFechaEjec from dual;
    update eam_activos_temp set fecha_act = vFechaEjec;
    commit;
    update eam_ubicacion_temp set fecha_act = vFechaEjec;
    commit;
  
    --Manejo de la fecha de actualizacion
    merge into eam_activos_temp nuevo
    using eam_activos_all viejo
    on (viejo.g3e_fid = nuevo.g3e_fid)
    when matched then
      update
         set nuevo.fecha_act = viejo.fecha_act
       where (nvl(nuevo.codigo_activo, 0) = nvl(viejo.codigo_activo, 0) and
             nvl(nuevo.ubicacion, 0) = nvl(viejo.ubicacion, 0) and
             nvl(nuevo.fid_padre, 0) = nvl(viejo.fid_padre, 0) and
             nvl(nuevo.nivel_superior, 0) = nvl(viejo.nivel_superior, 0))
         and nuevo.clase = viejo.clase
         and nuevo.g3e_fno = viejo.g3e_fno;
    commit;
  
    merge into eam_ubicacion_temp nuevo
    using eam_ubicacion viejo
    on (viejo.g3e_fid = nuevo.g3e_fid)
    when matched then
      update
         set nuevo.fecha_act = viejo.fecha_act
       where (nvl(nuevo.codigo, 0) = nvl(viejo.codigo, 0) and
             nvl(nuevo.codigo_ubicacion, 0) =
             nvl(viejo.codigo_ubicacion, 0) and
             nvl(nuevo.nivel_superior, 0) = nvl(viejo.nivel_superior, 0))
         and nuevo.clase = viejo.clase
         and nuevo.g3e_fno = viejo.g3e_fno;
    commit;
  
    commit;
    delete from eam_ubicacion;
    commit;
    insert into eam_ubicacion
      select * from eam_ubicacion_temp;
    commit;
  
    --Manejo de los retirados
    insert into eam_activos_ret
      select ea.tipo_red,
             ea.nombre_red,
             ea.clase,
             ea.g3e_fid,
             ea.g3e_fno,
             ea.codigo_activo,
             ea.ubicacion,
             ea.nivel,
             ea.fid_padre,
             ea.nivel_superior,
             ea.descripcion,
             ea.activo,
             ea.ordem,
             vFechaEjec
        from eam_activos_all ea
       inner join ccomun c
          on (c.g3e_fid = ea.g3e_fid and c.g3e_fno = ea.g3e_fno)
       where c.estado = 'RETIRADO'
         and not exists (select g3e_fid
                from eam_activos_ret
               where g3e_fid = ea.g3e_fid
                 and g3e_fno = ea.g3e_fno);
    commit;
  
    --Actualizar tabla eam_activos_all = elementos en operacion + retirados - returados parciales
    delete from eam_activos_all;
    commit;
  
    -- los que no fueron retirados
    insert into eam_activos_all
      select ea.*
        from eam_activos_temp ea
       where not exists
       (select g3e_fid from eam_activos_ret where g3e_fid = ea.g3e_fid);
    commit;
  
    -- los que no son retiros lineares agrupados
    insert into eam_activos_all
      select * from eam_activos_ret where nvl(activo, 0) = 0;
    commit;
  
    -- los que son retiros lineares completos
    insert into eam_activos_all
      select *
        from eam_activos_ret
       where activo not in
             (select distinct activo
                from eam_activos_all
               where activo in (select distinct activo
                                  from eam_activos_ret
                                 where nvl(activo, 0) != 0))
         and nvl(activo, 0) != 0;
    commit;
  
  end EAM_TAXONOMIA;

  procedure EAM_LIMPIAR_TABLAS is
  begin
    execute immediate 'TRUNCATE TABLE EAM_ACTIVOS_RET';
    execute immediate 'TRUNCATE TABLE EAM_UBICACION';
    execute immediate 'TRUNCATE TABLE EAM_ACTIVOS_TEMP';
    execute immediate 'TRUNCATE TABLE EAM_UBICACION_TEMP';
    execute immediate 'TRUNCATE TABLE EAM_ACTIVOS_ALL';
  end;

  procedure EAM_RESPALDAR_TABLAS is
  begin
  
    begin
      execute immediate 'DROP TABLE EAM_ACTIVOS_TEMP_BKP';
    end;
  
    begin
      execute immediate 'DROP TABLE EAM_ACTIVOS_RET_BKP';
    end;
  
    begin
      execute immediate 'DROP TABLE EAM_UBICACION_BKP';
    end;
  
    begin
      execute immediate 'DROP TABLE EAM_ACTIVOS_ALL_BKP';
    end;
  
    execute immediate 'CREATE TABLE EAM_ACTIVOS_TEMP_BKP AS SELECT * FROM EAM_ACTIVOS_TEMP';
    execute immediate 'CREATE TABLE EAM_ACTIVOS_RET_BKP AS SELECT * FROM EAM_ACTIVOS_RET';
    execute immediate 'CREATE TABLE EAM_ACTIVOS_ALL_BKP AS SELECT * FROM EAM_ACTIVOS_ALL';
    execute immediate 'CREATE TABLE EAM_UBICACION_BKP AS SELECT * FROM EAM_UBICACION';
  end;

  function EAM_ESMETROPOLITANA(pFID IN NUMBER, pFNO in NUMBER) return NUMBER as
    vMunID varchar2(50);
    vCount number(2);
  begin
  
    select municipio_geo
      into vMunID
      from ccomun
     where g3e_fid = pFID
       and g3e_fno = pFNO;
  
    if vMunID is null then
      insert into eam_errors
      values
        (null, pFid, pFno, sysdate, 'Elemento sin Municipio');
      commit;
      return 0;
    end if;
  
    select count(1)
      into vCount
      from eam_config
     where valor = vMunID
       and descripcion = 'RedMetropolitanaMunId';
  
    return vCount;
  
  exception
    when others then
      return 0;
    
  end EAM_ESMETROPOLITANA;

end EAM_EPM;
/
