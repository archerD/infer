(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd

let find =
  let select_statement =
    ResultsDatabase.register_statement "SELECT proc_attributes FROM procedures WHERE proc_uid = :k"
  in
  fun proc_uid ->
    ResultsDatabase.with_registered_statement select_statement ~f:(fun db select_stmt ->
        Sqlite3.bind select_stmt 1 (Sqlite3.Data.TEXT proc_uid)
        |> SqliteUtils.check_result_code db ~log:"find bind proc name" ;
        SqliteUtils.result_single_column_option ~finalize:false ~log:"Attributes.find" db
          select_stmt
        |> Option.map ~f:ProcAttributes.SQLite.deserialize )


let load, clear_cache, store =
  (* capture DB attribute cache: only keeps positive entries as analysis may add entries *)
  let cache : ProcAttributes.t Procname.Hash.t = Procname.Hash.create 1 in
  let load pname =
    match Procname.Hash.find_opt cache pname with
    | Some _ as result ->
        result
    | None ->
        let result = find (Procname.to_unique_id pname) in
        Option.iter result ~f:(Procname.Hash.add cache pname) ;
        result
  in
  let clear_cache () = Procname.Hash.clear cache in
  let store ~proc_desc (attr : ProcAttributes.t) =
    if attr.is_defined && Option.is_none proc_desc then
      Logging.die InternalError "Was given DEFINED procedure without procdesc: %a@."
        ProcAttributes.pp attr ;
    if (not attr.is_defined) && Option.is_some proc_desc then
      Logging.die InternalError
        "Was given UNDEFINED procedure WITH procdesc:@\nAttributes:%a@\nProcdesc:%a@."
        ProcAttributes.pp attr (Pp.option Procdesc.pp_signature) proc_desc ;
    let pname = attr.proc_name in
    let proc_uid = Procname.to_unique_id pname in
    let proc_name = Procname.SQLite.serialize pname in
    let cfg = Procdesc.SQLite.serialize proc_desc in
    let proc_attributes = ProcAttributes.SQLite.serialize attr in
    let source_file = SourceFile.SQLite.serialize attr.loc.Location.file in
    let callees =
      Option.value_map proc_desc ~f:Procdesc.get_static_callees ~default:[]
      |> Procname.SQLiteList.serialize
    in
    DBWriter.replace_attributes ~proc_uid ~proc_name ~source_file ~proc_attributes ~cfg ~callees ;
    Procname.Hash.remove cache pname
  in
  (load, clear_cache, store)


let is_no_return pname = match load pname with Some {is_no_return} -> is_no_return | _ -> false
