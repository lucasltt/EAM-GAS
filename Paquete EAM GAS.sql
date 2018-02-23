create or replace package EAM_EPM is

  -- Creación
  -- Version : 1.0
  -- Author  : Lucas Turchet
  -- Created : 23/02/18
  -- Purpose : Disponibilización de Activos para Integración con EAM GAS

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
    vTramos      number; --cantidad de tramos
    vPerID       cpertenencia.G3E_ID%type; --guarda el id de la pertenencia
    vRamalFNO    number(5);
    vRamalFID    number(10);
    vRamalFecha  date;
    vFechaComun  date;
  
    --Configuraciones
    vClaseTramosMatriz            VARCHAR2(100);
    vUbicacionMatriz              VARCHAR2(100);
    vClaseEstacionSeccionamiento  VARCHAR2(100);
    vUbicacionEstSeccionamiento   VARCHAR2(100);
    vClaseInstrumentacion         VARCHAR2(100);
    vClaseObraCivilSeccionamiento VARCHAR2(100);
    vClaseByPass                  VARCHAR2(100);
    vClaseObraCivilMatriz         VARCHAR2(100);
    vClaseRamal                   VARCHAR2(100);
    vUbicacionRamal               VARCHAR2(100);
    vClaseCircuito                VARCHAR2(100);
    vSuperiorCircuito             VARCHAR2(100);
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
  
    --Linea Primaria -> Linea Matriz -> Obra Civil
    cursor lp_lm_oc is
      select protec.g3e_fid fid_protec,
             protec.g3e_fno fno_protec,
             tubp.g3e_fid   tub_fid
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
  
    delete from eam_activos;
    commit;
  
    delete from eam_errors;
    commit;
  
    delete from eam_ubicacion;
    commit;
  
    --Carga Configuración
    select valor
      into vClaseTramosMatriz
      from eam_config
     where descripcion = 'ClaseTramosMatriz';
    select valor
      into vUbicacionMatriz
      from eam_config
     where descripcion = 'UbicacionMatriz';
    select valor
      into vClaseEstacionSeccionamiento
      from eam_config
     where descripcion = 'ClaseEstacionSeccionamiento';
    select valor
      into vUbicacionEstSeccionamiento
      from eam_config
     where descripcion = 'UbicacionEstacionSeccionamiento';
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
      into vUbicacionRamal
      from eam_config
     where descripcion = 'UbicacionRamal';
    select valor
      into vClaseCircuito
      from eam_config
     where descripcion = 'ClaseCircuito';
    select valor
      into vSuperiorCircuito
      from eam_config
     where descripcion = 'SuperiorCircuito';
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
            insert into eam_activos
            values
              (vClaseTramosMatriz,
               elTrace.g3e_fid,
               elTrace.g3e_fno,
               (select g3e_username
                  from g3e_feature
                 where g3e_fno = eltrace.g3e_fno),
               codigo,
               vUbicacionMatriz,
               6,
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
        
          --Mirar sy lla valvula ya fue caculada
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
        
          insert into eam_activos
          values
            (vClaseEstacionSeccionamiento,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             (select g3e_username
                from g3e_feature
               where g3e_fno = eltrace.g3e_fno),
             codigo || '-6',
             vUbicacionEstSeccionamiento,
             6,
             null,
             null,
             null,
             null,
             sysdate);
        
          insert into eam_activos
          values
            (vClaseInstrumentacion,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             (select g3e_username
                from g3e_feature
               where g3e_fno = eltrace.g3e_fno),
             null,
             vUbicacionEstSeccionamiento,
             7,
             elTrace.g3e_fid,
             codigo || '-6',
             null,
             null,
             sysdate);
        
          insert into eam_activos
          values
            (vClaseObraCivilSeccionamiento,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             (select g3e_username
                from g3e_feature
               where g3e_fno = eltrace.g3e_fno),
             null,
             vUbicacionEstSeccionamiento,
             7,
             elTrace.g3e_fid,
             codigo || '-6',
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
            
              insert into eam_activos
              values
                (vClaseByPass,
                 bypass.g3e_fid,
                 bypass.g3e_fno,
                 (select g3e_username
                    from g3e_feature
                   where g3e_fno = eltrace.g3e_fno),
                 null,
                 vUbicacionEstSeccionamiento,
                 7,
                 elTrace.g3e_fid,
                 codigo_padre || '-6',
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
  
    --Linea Matriz, Obra Civil
    for clp_lm_oc in lp_lm_oc loop
      insert into eam_activos
      values
        (vClaseObraCivilMatriz,
         clp_lm_oc.fid_protec,
         clp_lm_oc.fno_protec,
         'Protección Mecanica',
         null,
         vUbicacionMatriz,
         6,
         clp_lm_oc.tub_fid,
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
                                  when t.g3e_fno = 14100 then
                                   4 --Tuberia Primaria
                                  else
                                   5 --Otros
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
          
            codigo := 'RML-' || vRamalFid;
          
            insert into eam_activos
            values
              (vClaseRamal,
               vRamalFid,
               vRamalFno,
               (select g3e_username
                  from g3e_feature
                 where g3e_fno = vRamalFno),
               codigo,
               vUbicacionRamal,
               6,
               null,
               null,
               0,
               0,
               sysdate);
          
            --Aprovechar y generar la ubicación del circuito
            insert into eam_ubicacion
            values
              (vClaseCircuito,
               vRamalFid,
               vRamalFno,
               (select g3e_username
                  from g3e_feature
                 where g3e_fno = vRamalFno),
               cRamal.Tipo_Nombre,
               'CIR-' || cRamal.Tipo_Nombre,
               5,
               vSuperiorCircuito,
               sysdate);
            commit;
          end if;
        
          insert into eam_activos
          values
            (vClaseTuberiaRamal,
             elTrace.g3e_fid,
             elTrace.g3e_fno,
             (select g3e_username
                from g3e_feature
               where g3e_fno = elTrace.g3e_fno),
             null,
             vUbicacionRamal,
             7,
             vRamalFid,
             codigo,
             0,
             0,
             sysdate);
          commit;
        end if;
      
      end loop;
    end loop;
  
    --Ramal, Obra Civil
    for clp_rm_oc in lp_rm_oc loop
      insert into eam_activos
      values
        (vClaseObraCivilRamal,
         clp_rm_oc.fid_protec,
         clp_rm_oc.fno_protec,
         'Protección Mecanica',
         'RML-' || clp_rm_oc.ramal,
         vUbicacionRamal,
         7,
         clp_rm_oc.tub_fid,
         null,
         0,
         0,
         sysdate);
    end loop;
    commit;
  
    --Linea Secundaria, Activos
    for circuito in (select * from eam_ubicacion) loop
    
      --Arteria
      insert into eam_activos
      values
        (vClaseArteria,
         circuito.g3e_fid,
         circuito.g3e_fno,
         circuito.activo_nombre,
         'ART-' || circuito.codigo,
         circuito.codigo_ubicacion,
         6,
         null,
         null,
         0,
         0,
         sysdate);
    
      --Polivalvula Arteria
      for activo in (select g3e_fid, g3e_fno
                       from cconectividad_g
                      where g3e_fno = 14700
                        and nombre_circuito = circuito.codigo) loop
        insert into eam_activos
        values
          ('POLIVALVULA ARTERIA',
           activo.g3e_fid,
           activo.g3e_fno,
           (select g3e_username
              from g3e_feature
             where g3e_fno = activo.g3e_fno),
           null,
           circuito.codigo_ubicacion,
           7,
           circuito.g3e_fid,
           'ART-' || circuito.codigo,
           0,
           0,
           sysdate);
      end loop;
      commit;
    
      --Tuberia Arteria
      for activo in (select g3e_fid, g3e_fno
                       from cconectividad_g
                      where g3e_fno = 14600
                        and nombre_circuito = circuito.codigo) loop
        insert into eam_activos
        values
          (vClaseTuberiaArteria,
           activo.g3e_fid,
           activo.g3e_fno,
           (select g3e_username
              from g3e_feature
             where g3e_fno = activo.g3e_fno),
           null,
           circuito.codigo_ubicacion,
           7,
           circuito.g3e_fid,
           'ART-' || circuito.codigo,
           0,
           0,
           sysdate);
      end loop;
      commit;
    
      --Obra Civil Arteria
      for activo in ls_ar_oc(circuito.codigo) loop
        insert into eam_activos
        values
          (vClaseObraCivilArteria,
           activo.fid_protec,
           activo.fno_protec,
           (select g3e_username
              from g3e_feature
             where g3e_fno = activo.fno_protec),
           null,
           circuito.codigo_ubicacion,
           7,
           activo.fid_tuberia,
           'ART-' || circuito.codigo,
           0,
           0,
           sysdate);
      
      end loop;
      commit;
    
      --Anillo y Polivalvula Anillo
      for activo in (select g3e_fid, g3e_fno, codigo_valvula
                       from cconectividad_g
                      where g3e_fno = 15100
                        and nombre_circuito = circuito.codigo) loop
        insert into eam_activos
        values
          (vClaseAnillo,
           activo.g3e_fid,
           activo.g3e_fno,
           (select g3e_username
              from g3e_feature
             where g3e_fno = activo.g3e_fno),
           activo.codigo_valvula || '-6',
           circuito.codigo_ubicacion,
           6,
           circuito.g3e_fid,
           null,
           0,
           0,
           sysdate);
      
        insert into eam_activos
        values
          (vClasePolivalvulaAnillo,
           activo.g3e_fid,
           activo.g3e_fno,
           (select g3e_username
              from g3e_feature
             where g3e_fno = activo.g3e_fno),
           null,
           circuito.codigo_ubicacion,
           7,
           circuito.g3e_fid,
           activo.codigo_valvula || '-6',
           0,
           0,
           sysdate);
      end loop;
      commit;
    
      --Tuberia Anillo
      for activo in (select g3e_fid, g3e_fno, codigo_valvula
                       from cconectividad_g
                      where g3e_fno = 15000
                        and nombre_circuito = circuito.codigo) loop
        insert into eam_activos
        values
          (vClaseTuberiaAnillo,
           activo.g3e_fid,
           activo.g3e_fno,
           (select g3e_username
              from g3e_feature
             where g3e_fno = activo.g3e_fno),
           null,
           circuito.codigo_ubicacion,
           7,
           circuito.g3e_fid,
           activo.codigo_valvula || '-6',
           0,
           0,
           sysdate);
      end loop;
      commit;
    
      --Obra Civil Anillo
      for activo in ls_an_oc(circuito.codigo) loop
        insert into eam_activos
        values
          (vClaseObraCivilAnillo,
           activo.fid_protec,
           activo.fno_protec,
           (select g3e_username
              from g3e_feature
             where g3e_fno = activo.fno_protec),
           null,
           circuito.codigo_ubicacion,
           7,
           activo.fid_tuberia,
           activo.codigo_valvula || '-6',
           0,
           0,
           sysdate);
      
      end loop;
      commit;
    
    end loop;
  
  end EAM_TAXONOMIA;

end EAM_EPM;
/