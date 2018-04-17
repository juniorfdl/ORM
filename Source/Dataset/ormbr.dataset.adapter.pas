{
      ORM Brasil é um ORM simples e descomplicado para quem utiliza Delphi

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

{ @abstract(ORMBr Framework.)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @author(Skype : ispinheiro)
  @abstract(Website : http://www.ormbr.com.br)
  @abstract(Telagram : https://t.me/ormbr)

  ORM Brasil é um ORM simples e descomplicado para quem utiliza Delphi.
}

unit ormbr.dataset.adapter;

interface

uses
  DB,
  Rtti,
  TypInfo,
  Classes,
  SysUtils,
  StrUtils,
  Variants,
  Generics.Collections,
  /// orm
  ormbr.criteria,
  ormbr.dataset.bind,
  ormbr.mapping.classes,
  ormbr.types.mapping,
  ormbr.session.dataset,
  ormbr.factory.interfaces,
  ormbr.dataset.base.adapter;

type
  /// <summary>
  /// M - Object M
  /// </summary>
  TDataSetAdapter<M: class, constructor> = class(TDataSetBaseAdapter<M>)
  private
    function GetRelationFields(ATable: TTableMapping; ADetail: TDataSetBaseAdapter<M>;
      var ACriteria: ICriteria): Boolean;
    procedure ExecuteCheckValidate;
  protected
    FConnection: IDBConnection;
    FSession: TSessionDataSet<M>;
    procedure OpenDataSetChilds; override;
    procedure RefreshDataSetOneToOneChilds(AFieldName: string); override;
    procedure DoAfterScroll(DataSet: TDataSet); override;
    procedure DoDataChange(Sender: TObject; Field: TField); override;
    procedure DoBeforeDelete(DataSet: TDataSet); override;
    procedure DoBeforePost(DataSet: TDataSet); override;
    procedure DoNewRecord(DataSet: TDataSet); override;
    procedure CancelUpdates; override;
    procedure NextPacket; override;
    procedure RefreshRecord; override;
    procedure Lazy(const AOwner: M); override;
    function Find: TObjectList<M>; overload; override;
    function Find(const AID: Integer): M; overload; override;
    function Find(const AID: string): M; overload; override;
    function FindWhere(const AWhere: string; const AOrderBy: string = ''): TObjectList<M>; override;
  public
    constructor Create(AConnection: IDBConnection; ADataSet:
      TDataSet; APageSize: Integer; AMasterObject: TObject); overload;
    destructor Destroy; override;
  end;

implementation

uses
  ormbr.mapping.explorer,
  ormbr.objects.helper,
  ormbr.rtti.helper,
  ormbr.dataset.fields,
  ormbr.mapping.exceptions;

{ TDataSetAdapter<M> }

procedure TDataSetAdapter<M>.CancelUpdates;
begin
  FSession.ModifiedFields.Items[M.ClassName].Clear;
end;

constructor TDataSetAdapter<M>.Create(AConnection: IDBConnection; ADataSet: TDataSet; APageSize: Integer;
  AMasterObject: TObject);
begin
  FConnection := AConnection;
  inherited Create(ADataSet, APageSize, AMasterObject);
  /// <summary>
  /// Passa de fora, qual Session será usado pelo Adapter
  /// </summary>
  FSession := TSessionDataSet<M>.Create(Self, AConnection, APageSize);
end;

destructor TDataSetAdapter<M>.Destroy;
begin
  FSession.Free;
  inherited;
end;

procedure TDataSetAdapter<M>.DoAfterScroll(DataSet: TDataSet);
begin
  if DataSet.State in [dsBrowse] then
    OpenDataSetChilds;
  inherited;
end;

procedure TDataSetAdapter<M>.DoBeforeDelete(DataSet: TDataSet);
begin
  inherited;
  /// <summary>
  /// Alimenta a lista com registros deletados
  /// </summary>
  FSession.DeleteList.Add(M.Create);
  TBindDataSet.GetInstance.SetFieldToProperty(FOrmDataSet, FSession.DeleteList.Last);
end;

procedure TDataSetAdapter<M>.DoBeforePost(DataSet: TDataSet);
begin
  inherited DoBeforePost(DataSet);
  /// <summary>
  /// Rotina de validação se o campo foi deixado null
  /// </summary>
  ExecuteCheckValidate;
end;

procedure TDataSetAdapter<M>.DoDataChange(Sender: TObject; Field: TField);
begin
  inherited DoDataChange(Sender, Field);
  if FOrmDataSet.State in [dsInsert, dsEdit] then
  begin
    if Field <> nil then
    begin
      if Field.FieldKind = fkData then
      begin
        if Field.FieldName <> cInternalField then
        begin
//          if Field.NewValue <> Field.OldValue then
//          begin
            if FOrmDataSet.State in [dsEdit] then
              if FSession.ModifiedFields.Items[M.ClassName].IndexOf(Field.FieldName) = -1 then
                FSession.ModifiedFields.Items[M.ClassName].Add(Field.FieldName);
            /// <summary>
            /// Atualiza o registro da tabela externa, se o campo alterado
            /// pertencer a um relacionamento OneToOne ou ManyToOne
            /// </summary>
            RefreshDataSetOneToOneChilds(Field.FieldName);
//          end;
        end;
      end;
    end;
  end;
end;

procedure TDataSetAdapter<M>.ExecuteCheckValidate;
var
  LColumn: TColumnMapping;
  LColumns: TColumnMappingList;
begin
  LColumns := FSession.Explorer.GetMappingColumn(FCurrentInternal.ClassType);
  for LColumn in LColumns do
  begin
    if LColumn.IsNoInsert then
      Continue;
    if LColumn.IsNoUpdate then
      Continue;
    if LColumn.IsJoinColumn then
      Continue;
    if LColumn.IsNoValidate then
      Continue;
    if LColumn.PropertyRtti.IsNullable then
      Continue;

    if FOrmDataSet.FieldValues[LColumn.ColumnName] = Null then
      raise EFieldValidate.Create(FCurrentInternal.ClassName + '.' + LColumn.ColumnName,
                                  FOrmDataSet.FieldByName(LColumn.ColumnName).ConstraintErrorMessage);
  end;
end;

function TDataSetAdapter<M>.Find: TObjectList<M>;
begin
  Result := FSession.Find;
end;

function TDataSetAdapter<M>.Find(const AID: Integer): M;
begin
  Result := FSession.Find(AID);
end;

function TDataSetAdapter<M>.Find(const AID: string): M;
begin
  Result := FSession.Find(AID);
end;

function TDataSetAdapter<M>.FindWhere(const AWhere, AOrderBy: string): TObjectList<M>;
begin
  Result := FSession.FindWhere(AWhere, AOrderBy);
end;

procedure TDataSetAdapter<M>.OpenDataSetChilds;
var
  LTable: TTableMapping;
  LDataSetChild: TDataSetBaseAdapter<M>;
  LCriteria: ICriteria;
begin
  inherited;
  if FOrmDataSet.Active then
  begin
     if FOrmDataSet.RecordCount > 0 then
     begin
        /// <summary>
        /// Se Count > 0 identifica-se que é o objeto é um Master
        /// </summary>
        if FMasterObject.Count > 0 then
        begin
           for LDataSetChild in FMasterObject.Values do
           begin
              LTable := FExplorer.GetMappingTable(LDataSetChild.FCurrentInternal.ClassType);
              if LTable <> nil then
              begin
                LCriteria := CreateCriteria.Select;
                /// <summary>
                /// Gera SELECT de abertura da tabela associada
                /// </summary>
                GetRelationFields(LTable, LDataSetChild, LCriteria);
                LDataSetChild.OpenAssociation(LCriteria.AsString);
              end;
           end;
        end;
     end;
  end;
end;

function TDataSetAdapter<M>.GetRelationFields(ATable: TTableMapping;
  ADetail: TDataSetBaseAdapter<M>; var ACriteria: ICriteria): Boolean;
var
  LAssociations: TAssociationMappingList;
  LAssociation: TAssociationMapping;
  LColumn: string;
  LFor: Integer;
begin
  Result := False;
  LAssociations := FExplorer.GetMappingAssociation(FCurrentInternal.ClassType);
  if LAssociations <> nil then
  begin
    for LAssociation in LAssociations do
    begin
      /// <summary>
      /// Verificação se tem algum mapeamento OneToOne para a classe.
      /// </summary>
      if LAssociation.ClassNameRef = ADetail.FCurrentInternal.ClassName then
      begin
        /// <summary>
        /// Verificação se foi relacionado uma lista de campos para o Select, caso não, Select All
        /// </summary>
        if LAssociation.ColumnsSelectRef.Count > 0 then
        begin
          for LFor := 0 to LAssociation.ColumnsNameRef.Count -1 do
            ACriteria.Column(ATable.Name + '.' + LAssociation.ColumnsNameRef[LFor]);
          for LColumn in LAssociation.ColumnsSelectRef do
            ACriteria.Column(ATable.Name + '.' + LColumn);
        end
        else
          ACriteria.All;
        /// <summary>
        /// From pelo nome da classe de referencia e aplicado o Where pela Coluna de referencia.
        /// </summary>
        ACriteria.From(ATable.Name);
        for LFor := 0 to LAssociation.ColumnsNameRef.Count -1 do
          ACriteria.Where(ATable.Name + '.' +
                          LAssociation.ColumnsNameRef[LFor] + '=' +
                          TBindDataSet.GetInstance.GetFieldValue(FOrmDataSet,
                                                                 LAssociation.ColumnsName[LFor],
                                                                 FOrmDataSet.FieldByName(LAssociation.ColumnsName[LFor]).DataType));
        Result := True;
      end;
    end;
  end;
end;

procedure TDataSetAdapter<M>.Lazy(const AOwner: M);
var
  LTable: TTableMapping;
  LCriteria: ICriteria;
begin
  inherited;
  if AOwner <> nil then
  begin
    if FOwnerMasterObject = nil then
    begin
      if not FOrmDataSet.Active then
      begin
        SetMasterObject(AOwner);
        LTable := FExplorer.GetMappingTable(FCurrentInternal.ClassType);
        if LTable <> nil then
        begin
          LCriteria := CreateCriteria.Select;
          /// <summary>
          /// Gera SELECT de abertura da tabela associada
          /// </summary>
          GetRelationFields(LTable, Self, LCriteria);
          Open(LCriteria.AsString);
        end;
      end;
    end;
  end
  else
  begin
    if FOwnerMasterObject <> nil then
    begin
      if TDataSetBaseAdapter<M>(FOwnerMasterObject).FOrmDataSet.Active then
      begin
        SetMasterObject(nil);
        Close;
      end;
    end
  end;
end;

procedure TDataSetAdapter<M>.NextPacket;
var
  LBookMark: TBookmark;
begin
  inherited;
  FOrmDataSet.DisableControls;
  DisableDataSetEvents;
  LBookMark := FOrmDataSet.Bookmark;
  try
    FSession.NextPacket;
  finally
    FOrmDataSet.GotoBookmark(LBookMark);
    FOrmDataSet.EnableControls;
    EnableDataSetEvents;
  end;
end;

procedure TDataSetAdapter<M>.RefreshDataSetOneToOneChilds(AFieldName: string);
var
  LTable: TTableMapping;
  LAssociations: TAssociationMappingList;
  LAssociation: TAssociationMapping;
  LDataSetChild: TDataSetBaseAdapter<M>;
  LCriteria: ICriteria;
begin
  inherited;
  if FOrmDataSet.Active then
  begin
    LAssociations := FExplorer.GetMappingAssociation(FCurrentInternal.ClassType);
    if LAssociations <> nil then
    begin
      for LAssociation in LAssociations do
      begin
        if LAssociation.ColumnsName.IndexOf(AFieldName) > -1 then
        begin
          if LAssociation.Multiplicity in [OneToOne, ManyToOne] then
          begin
            LDataSetChild := FMasterObject.Items[LAssociation.ClassNameRef];
            if LDataSetChild <> nil then
            begin
              LTable := FExplorer.GetMappingTable(LDataSetChild.FCurrentInternal.ClassType);
              if LTable <> nil then
              begin
                LCriteria := CreateCriteria.Select;
                /// <summary>
                /// Gera SELECT de abertura da tabela associada
                /// </summary>
                GetRelationFields(LTable, LDataSetChild, LCriteria);
                LDataSetChild.OpenAssociation(LCriteria.AsString);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TDataSetAdapter<M>.RefreshRecord;
var
  LPrimaryKey: TPrimaryKeyMapping;
begin
  inherited;
  LPrimaryKey := FSession.Explorer.GetMappingPrimaryKey(FCurrentInternal.ClassType);
  if LPrimaryKey <> nil then
  begin
    FOrmDataSet.DisableControls;
    DisableDataSetEvents;
    try
      FSession.RefreshRecord(LPrimaryKey.Columns[0]);
    finally
      FOrmDataSet.EnableControls;
      EnableDataSetEvents;
    end;
  end;
end;

procedure TDataSetAdapter<M>.DoNewRecord(DataSet: TDataSet);
begin
  /// <summary>
  /// Limpa os datasets em memória para receberem novos valores
  /// </summary>
  EmptyDataSetChilds;
  inherited DoNewRecord(DataSet);
end;

end.
