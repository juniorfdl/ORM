{
      ormbr Brasil é um ormbr simples e descomplicado para quem utiliza Delphi

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Versão 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos é permitido copiar e distribuir cópias deste documento de
       licença, mas mudá-lo não é permitido.

       Esta versão da GNU Lesser General Public License incorpora
       os termos e condições da versão 3 da GNU General Public License
       Licença, complementado pelas permissões adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(ormbr Framework.)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @author(Skype : ispinheiro)
  @abstract(Website : http://www.ormbr.com.br)
  @abstract(Telagram : https://t.me/ormbr)

  ormbr Brasil é um ormbr simples e descomplicado para quem utiliza Delphi.
}

unit ormbr.restdataset.fdmemtable;

interface

uses
  DB,
  Rtti,
  Classes,
  SysUtils,
  Variants,
  Generics.Collections,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  /// ormbr
  ormbr.criteria,
  ormbr.restdataset.adapter,
  ormbr.dataset.base.adapter,
  ormbr.dataset.events,
  ormbr.factory.interfaces,
  ormbr.types.mapping,
  ormbr.mapping.classes,
  ormbr.rtti.helper,
  ormbr.objects.helper,
  ormbr.mapping.attributes,
  ormbr.session.datasnap;

type
  /// <summary>
  /// Captura de eventos específicos do componente TFDMemTable
  /// </summary>
  TRESTFDMemTableEvents = class(TDataSetEvents)
  private
    FBeforeApplyUpdates: TFDDataSetEvent;
    FAfterApplyUpdates: TFDAfterApplyUpdatesEvent;
  public
    property BeforeApplyUpdates: TFDDataSetEvent read FBeforeApplyUpdates write FBeforeApplyUpdates;
    property AfterApplyUpdates: TFDAfterApplyUpdatesEvent read FAfterApplyUpdates write FAfterApplyUpdates;
  end;

  /// <summary>
  /// Adapter TClientDataSet para controlar o Modelo e o Controle definido por:
  /// M - Object Model
  /// </summary>
  TRESTFDMemTableAdapter<M: class, constructor> = class(TRESTDataSetAdapter<M>)
  private
    FOrmDataSet: TFDMemTable;
    FMemTableEvents: TRESTFDMemTableEvents;
    procedure DoBeforeApplyUpdates(DataSet: TFDDataSet);
    procedure DoAfterApplyUpdates(DataSet: TFDDataSet; AErrors: Integer);
    procedure FilterDataSetChilds;
  protected
    procedure EmptyDataSetChilds; override;
    procedure DoBeforeDelete(DataSet: TDataSet); override;
    procedure GetDataSetEvents; override;
    procedure SetDataSetEvents; override;
    procedure OpenAssociation(const ASQL: string); override;
    procedure OpenIDInternal(const AID: Variant); override;
    procedure OpenSQLInternal(const ASQL: string); override;
    procedure OpenWhereInternal(const AWhere: string; const AOrderBy: string = ''); override;
    procedure ApplyInserter(const MaxErros: Integer); override;
    procedure ApplyUpdater(const MaxErros: Integer); override;
    procedure ApplyDeleter(const MaxErros: Integer); override;
    procedure ApplyInternal(const MaxErros: Integer); override;
    procedure ApplyUpdates(const MaxErros: Integer); override;
  public
    constructor Create(ADataSet: TDataSet; APageSize: Integer; AMasterObject: TObject); overload; override;
    destructor Destroy; override;
  end;

implementation

uses
  ormbr.dataset.bind,
  ormbr.dataset.fields;

{ TRESTFDMemTableAdapter<M> }

constructor TRESTFDMemTableAdapter<M>.Create(ADataSet: TDataSet; APageSize: Integer;
  AMasterObject: TObject);
begin
  inherited Create(ADataSet, APageSize, AMasterObject);
  /// <summary>
  /// Captura o component TFDMemTable da IDE passado como parâmetro
  /// </summary>
  FOrmDataSet := ADataSet as TFDMemTable;
  FMemTableEvents := TRESTFDMemTableEvents.Create;
  /// <summary>
  /// Captura e guarda os eventos do dataset
  /// </summary>
  GetDataSetEvents;
  /// <summary>
  /// Seta os eventos do ormbr no dataset, para que ele sejam disparados
  /// </summary>
  SetDataSetEvents;
  ///
  if not FOrmDataSet.Active then
  begin
    FOrmDataSet.FetchOptions.RecsMax := 300000;
    FOrmDataSet.ResourceOptions.SilentMode := True;
    FOrmDataSet.UpdateOptions.LockMode := lmNone;
    FOrmDataSet.UpdateOptions.LockPoint := lpDeferred;
    FOrmDataSet.UpdateOptions.FetchGeneratorsPoint := gpImmediate;
    FOrmDataSet.CreateDataSet;
    FOrmDataSet.Open;
    FOrmDataSet.CachedUpdates := False;
    FOrmDataSet.LogChanges := False;
  end;
end;

destructor TRESTFDMemTableAdapter<M>.Destroy;
begin
  FOrmDataSet := nil;
  FMemTableEvents.Free;
  inherited;
end;

procedure TRESTFDMemTableAdapter<M>.DoAfterApplyUpdates(DataSet: TFDDataSet; AErrors: Integer);
begin
  if Assigned(FMemTableEvents.AfterApplyUpdates) then
     FMemTableEvents.AfterApplyUpdates(DataSet, AErrors);
end;

procedure TRESTFDMemTableAdapter<M>.DoBeforeApplyUpdates(DataSet: TFDDataSet);
begin
  if Assigned(FMemTableEvents.BeforeApplyUpdates) then
     FMemTableEvents.BeforeApplyUpdates(DataSet);
end;

procedure TRESTFDMemTableAdapter<M>.DoBeforeDelete(DataSet: TDataSet);
begin
  inherited DoBeforeDelete(DataSet);
  /// <summary>
  /// Deleta registros de todos os DataSet filhos
  /// </summary>
  EmptyDataSetChilds;
end;

procedure TRESTFDMemTableAdapter<M>.EmptyDataSetChilds;
var
  LChild: TDataSetBaseAdapter<M>;
begin
  inherited;
  for LChild in FMasterObject.Values do
  begin
     if TRESTFDMemTableAdapter<M>(LChild).FOrmDataSet.Active then
       TRESTFDMemTableAdapter<M>(LChild).FOrmDataSet.EmptyDataSet;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.FilterDataSetChilds;
var
  LRttiType: TRttiType;
  LAssociations: TAssociationMappingList;
  LAssociation: TAssociationMapping;
  LDataSetChild: TDataSetBaseAdapter<M>;
  LFor: Integer;
  LFields: string;
  LIndexFields: string;
begin
  if FOrmDataSet.Active then
  begin
    LAssociations := FExplorer.GetMappingAssociation(FCurrentInternal.ClassType);
    if LAssociations <> nil then
    begin
      for LAssociation in LAssociations do
      begin
        if LAssociation.PropertyRtti.isList then
          LRttiType := LAssociation.PropertyRtti.GetTypeValue(LAssociation.PropertyRtti.PropertyType)
        else
          LRttiType := LAssociation.PropertyRtti.PropertyType;

        if FMasterObject.ContainsKey(LRttiType.AsInstance.MetaclassType.ClassName) then
        begin
          LDataSetChild := FMasterObject.Items[LRttiType.AsInstance.MetaclassType.ClassName];
          LFields := '';
          LIndexFields := '';
          try
            TFDMemTable(LDataSetChild.FOrmDataSet).MasterSource := FOrmDataSource;
            for LFor := 0 to LAssociation.ColumnsName.Count -1 do
            begin
              LFields := LFields + LAssociation.ColumnsNameRef[LFor];
              LIndexFields := LIndexFields + LAssociation.ColumnsName[LFor];
              if LAssociation.ColumnsName.Count -1 > LFor then
              begin
                LFields := LFields + '; ';
                LIndexFields := LIndexFields + '; ';
              end;
            end;
            TFDMemTable(LDataSetChild.FOrmDataSet).IndexFieldNames := LIndexFields;
            TFDMemTable(LDataSetChild.FOrmDataSet).MasterFields := LFields;
          finally
          end;
        end;
      end;
    end;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.GetDataSetEvents;
begin
  inherited;
  if Assigned(FOrmDataSet.BeforeApplyUpdates) then
    FMemTableEvents.BeforeApplyUpdates := FOrmDataSet.BeforeApplyUpdates;
  if Assigned(FOrmDataSet.AfterApplyUpdates)  then
    FMemTableEvents.AfterApplyUpdates  := FOrmDataSet.AfterApplyUpdates;
end;

procedure TRESTFDMemTableAdapter<M>.OpenAssociation(const ASQL: string);
begin
  OpenSQLInternal(ASQL);
end;

procedure TRESTFDMemTableAdapter<M>.OpenIDInternal(const AID: Variant);
begin
//  FOrmDataSet.BeginBatch;
  FOrmDataSet.DisableConstraints;
  FOrmDataSet.DisableControls;
  DisableDataSetEvents;
  try
    FOrmDataSet.EmptyDataSet;
    inherited;
    FSession.OpenID(AID);
    /// <summary>
    /// Filtra os registros nas sub-tabelas
    /// </summary>
    if FOwnerMasterObject = nil then
      FilterDataSetChilds;
  finally
    EnableDataSetEvents;
    FOrmDataSet.First;
    FOrmDataSet.EnableControls;
    FOrmDataSet.EnableConstraints;
//    FOrmDataSet.EndBatch;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.OpenSQLInternal(const ASQL: string);
begin
//  FOrmDataSet.BeginBatch;
  FOrmDataSet.DisableConstraints;
  FOrmDataSet.DisableControls;
  DisableDataSetEvents;
  try
    FOrmDataSet.EmptyDataSet;
    inherited;
    FSession.OpenSQL(ASQL);
    /// <summary>
    /// Filtra os registros nas sub-tabelas
    /// </summary>
    if FOwnerMasterObject = nil then
      FilterDataSetChilds;
  finally
    EnableDataSetEvents;
    FOrmDataSet.First;
    FOrmDataSet.EnableControls;
    FOrmDataSet.EnableConstraints;
//    FOrmDataSet.EndBatch;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.OpenWhereInternal(const AWhere, AOrderBy: string);
begin
//  FOrmDataSet.BeginBatch;
  FOrmDataSet.DisableConstraints;
  FOrmDataSet.DisableControls;
  DisableDataSetEvents;
  try
    FOrmDataSet.EmptyDataSet;
    inherited;
    FSession.OpenWhere(AWhere, AOrderBy);
    /// <summary>
    /// Filtra os registros nas sub-tabelas
    /// </summary>
    if FOwnerMasterObject = nil then
      FilterDataSetChilds;
  finally
    EnableDataSetEvents;
    FOrmDataSet.First;
    FOrmDataSet.EnableControls;
    FOrmDataSet.EnableConstraints;
//    FOrmDataSet.EndBatch;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.ApplyInternal(const MaxErros: Integer);
var
  LRecnoBook: TBookmark;
begin
  LRecnoBook := FOrmDataSet.GetBookmark;
  FOrmDataSet.DisableControls;
  FOrmDataSet.DisableConstraints;
  DisableDataSetEvents;
  try
    ApplyInserter(MaxErros);
    ApplyUpdater(MaxErros);
    ApplyDeleter(MaxErros);
  finally
    FOrmDataSet.GotoBookmark(LRecnoBook);
    FOrmDataSet.FreeBookmark(LRecnoBook);
    FOrmDataSet.EnableConstraints;
    FOrmDataSet.EnableControls;
    EnableDataSetEvents;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.ApplyDeleter(const MaxErros: Integer);
var
  LColumn: TColumnMapping;
  LObject: TObject;
begin
  inherited;
  /// <summary>
  /// Varre a lista de objetos excluídos e passa para a sessão REST
  /// </summary>
  for LObject in FSession.DeleteList do
    for LColumn in LObject.GetPrimaryKey do
      FSession.Delete(LColumn.PropertyRtti.GetValue(LObject).AsInteger);
end;

procedure TRESTFDMemTableAdapter<M>.ApplyInserter(const MaxErros: Integer);
var
  LObject: TObject;
  LProperty: TRttiProperty;
  LInsertList: TObjectList<M>;
  LDataSetChild: TDataSetBaseAdapter<M>;
begin
  inherited;
  /// Filtar somente os registros inseridos
  FOrmDataSet.Filter := cInternalField + '=' + IntToStr(Integer(dsInsert));
  FOrmDataSet.Filtered := True;
  FOrmDataSet.First;
  LInsertList := TObjectList<M>.Create;
  try
    while not FOrmDataSet.Eof do
    begin
       /// Append/Insert
       if TDataSetState(FOrmDataSet.Fields[FInternalIndex].AsInteger) in [dsInsert] then
       begin
         LObject := M.Create;
         TBindDataSet.GetInstance.SetFieldToProperty(FOrmDataSet, LObject);
         for LDataSetChild in FMasterObject.Values do
           LDataSetChild.FillMastersClass(LDataSetChild, LObject);
         ///
         LInsertList.Add(LObject);
         FOrmDataSet.Edit;
//         if FSession.ExistSequence then
//         begin
//           for LProperty in LObject.GetPrimaryKey do
//           begin
//             FOrmDataSet.Fields[LProperty.GetIndex].Value := LProperty.GetValue(TObject(LObject)).AsVariant;
//             /// <summary>
//             /// Atualiza o valor do AutoInc nas sub tabelas
//             /// </summary>
//             SetAutoIncValueChilds(FOrmDataSet.Fields[LProperty.GetIndex]);
//           end;
//         end;
         FOrmDataSet.Fields[FInternalIndex].AsInteger := -1;
         FOrmDataSet.Post;
       end;
    end;
    if LInsertList.Count > 0 then
      FSession.Insert(LInsertList);
  finally
    FOrmDataSet.Filtered := False;
    FOrmDataSet.Filter := '';
    LInsertList.Clear;
    LInsertList.Free;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.ApplyUpdater(const MaxErros: Integer);
var
  LObject: TObject;
  LUpdateList: TObjectList<M>;
  LDataSetChild: TDataSetBaseAdapter<M>;
begin
  inherited;
  /// Filtar somente os registros modificados
  FOrmDataSet.Filter := cInternalField + '=' + IntToStr(Integer(dsEdit));
  FOrmDataSet.Filtered := True;
  FOrmDataSet.First;
  LUpdateList := TObjectList<M>.Create;
  try
    while FOrmDataSet.RecordCount > 0 do
    begin
       /// Edit
       if TDataSetState(FOrmDataSet.Fields[FInternalIndex].AsInteger) in [dsEdit] then
       begin
//         if FSession.ModifiedFields.Count > 0 then
         LObject := M.Create;
         TBindDataSet.GetInstance.SetFieldToProperty(FOrmDataSet, LObject);
         for LDataSetChild in FMasterObject.Values do
           LDataSetChild.FillMastersClass(LDataSetChild, LObject);
         ///
         LUpdateList.Add(LObject);
         FOrmDataSet.Edit;
         FOrmDataSet.Fields[FInternalIndex].AsInteger := -1;
         FOrmDataSet.Post;
       end;
    end;
//    FSession.Update(LObject, M.ClassName);
    if LUpdateList.Count > 0 then
      FSession.Update(LUpdateList);
  finally
    FOrmDataSet.Filtered := False;
    FOrmDataSet.Filter := '';
    LUpdateList.Clear;
    LUpdateList.Free;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.ApplyUpdates(const MaxErros: Integer);
begin
  inherited;
  try
    DoBeforeApplyUpdates(FOrmDataSet);
    ApplyInternal(MaxErros);
    DoAfterApplyUpdates(FOrmDataSet, MaxErros);
  finally
    /// <summary>
    /// Lista os fields alterados a lista para novas alterações
    /// </summary>
    FSession.ModifiedFields.Items[M.ClassName].Clear;
    FSession.DeleteList.Clear;
  end;
end;

procedure TRESTFDMemTableAdapter<M>.SetDataSetEvents;
begin
  inherited;
  FOrmDataSet.BeforeApplyUpdates := DoBeforeApplyUpdates;
  FOrmDataSet.AfterApplyUpdates  := DoAfterApplyUpdates;
end;

end.
