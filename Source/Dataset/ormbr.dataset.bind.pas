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

unit ormbr.dataset.bind;

interface

uses
  DB,
  Rtti,
  Classes,
  SysUtils,
  TypInfo,
  Variants,
  /// orm
  ormbr.mapping.attributes,
  ormbr.mapping.rttiutils,
  ormbr.mapping.exceptions,
  ormbr.factory.interfaces,
  ormbr.rtti.helper,
  ormbr.objects.helper,
  ormbr.types.nullable;

type
  IBindDataSet = interface
    ['{8EAF6052-177E-4D4B-9E0A-386799C129FC}']
    procedure SetDataDictionary(ADataSet: TDataSet; AObject: TObject);
    procedure SetInternalInitFieldDefsObjectClass(ADataSet: TDataSet; AObject: TObject);
    procedure SetPropertyToField(AObject: TObject; ADataSet: TDataSet);
    procedure SetFieldToProperty(ADataSet: TDataSet; AObject: TObject);
    procedure SetFieldToField(AResultSet: IDBResultSet; ADataSet: TDataSet);
    function GetFieldValue(ADataSet: TDataSet; AFieldName: string; AFieldType: TFieldType): string;
  end;

  TBindDataSet = class(TInterfacedObject, IBindDataSet)
  private
  class var
    FInstance: IBindDataSet;
    FContext: TRttiContext;
    constructor CreatePrivate;
    procedure SetAggregateFieldDefsObjectClass(ADataSet: TDataSet; AObject: TObject);
    procedure SetCalcFieldDefsObjectClass(ADataSet: TDataSet; AObject: TObject);
  public
    { Public declarations }
    constructor Create;
    class function GetInstance: IBindDataSet;
    procedure SetDataDictionary(ADataSet: TDataSet; AObject: TObject);
    procedure SetInternalInitFieldDefsObjectClass(ADataSet: TDataSet; AObject: TObject);
    procedure SetPropertyToField(AObject: TObject; ADataSet: TDataSet);
    procedure SetFieldToProperty(ADataSet: TDataSet; AObject: TObject);
    procedure SetFieldToField(AResultSet: IDBResultSet; ADataSet: TDataSet);
    function GetFieldValue(ADataSet: TDataSet; AFieldName: string; AFieldType: TFieldType): string;
  end;

implementation

uses
  ormbr.dataset.fields,
  ormbr.types.mapping,
  ormbr.mapping.classes,
  ormbr.mapping.explorer,
  ormbr.types.blob;

{ TBindDataSet }

procedure TBindDataSet.SetPropertyToField(AObject: TObject; ADataSet: TDataSet);
var
  LColumn: TColumnMapping;
  LColumns: TColumnMappingList;
  LValue: Variant;
  LSameText: Boolean;
  LProperty: TRttiProperty;
begin
  /// <summary>
  /// Busca lista de columnas do mapeamento
  /// </summary>
  LColumns := TMappingExplorer.GetInstance.GetMappingColumn(AObject.ClassType);
  for LColumn in LColumns do
  begin
    if LColumn.IsJoinColumn then
      Continue;
    LProperty := LColumn.PropertyRtti;
    if LProperty.PropertyType.TypeKind = tkEnumeration then
    begin
      LValue := LProperty.GetEnumToFieldValue(AObject, LColumn.FieldType).AsVariant;
      LSameText := (ADataSet.FieldByName(LColumn.ColumnName).Value = LValue);
      if not LSameText then
        ADataSet.FieldByName(LColumn.ColumnName).Value := LValue;
    end
    else
    begin
      LValue := LProperty.GetNullableValue(AObject).AsVariant;
      LSameText := (ADataSet.FieldByName(LColumn.ColumnName).Value = LValue);
      if not LSameText then
      begin
        if LProperty.IsBlob then
        begin
          if ADataSet.FieldByName(LColumn.ColumnName).IsBlob then
            TBlobField(ADataSet.FieldByName(LColumn.ColumnName)).AsBytes :=
              LProperty.GetNullableValue(AObject).AsType<TBlob>.ToBytes
          else
            raise Exception.Create(Format('Column [%s] must have blob value',
                                   [ADataSet.FieldByName(LColumn.ColumnName).FieldName]));
        end
        else
          ADataSet.FieldByName(LColumn.ColumnName).Value := LValue;
      end;
    end;
  end;
end;

constructor TBindDataSet.Create;
begin
   raise Exception.Create('Para usar o BindDataSet use o método TBindDataSet.GetInstance()');
end;

constructor TBindDataSet.CreatePrivate;
begin
   inherited;
   FContext := TRttiContext.Create;
end;

function TBindDataSet.GetFieldValue(ADataSet: TDataSet; AFieldName: string;
  AFieldType: TFieldType): string;
begin
  case AFieldType of
    ftUnknown: ;
    ftString, ftDate, ftTime, ftDateTime, ftTimeStamp:
    begin
      Result := QuotedStr(ADataSet.FieldByName(AFieldName).AsString);
    end;
    ftInteger, ftSmallint, ftWord:
    begin
      Result := IntToStr(ADataSet.FieldByName(AFieldName).AsInteger);
    end;
    else
      Result := ADataSet.FieldByName(AFieldName).AsString;
{
   ftBoolean: ;
   ftFloat: ;
   ftCurrency: ;
   ftBCD: ;
   ftBytes: ;
   ftVarBytes: ;
   ftAutoInc: ;
   ftBlob: ;
   ftMemo: ;
   ftGraphic: ;
   ftFmtMemo: ;
   ftParadoxOle: ;
   ftDBaseOle: ;
   ftTypedBinary: ;
   ftCursor: ;
   ftFixedChar: ;
   ftWideString: ;
   ftLargeint: ;
   ftADT: ;
   ftArray: ;
   ftReference: ;
   ftDataSet: ;
   ftOraBlob: ;
   ftOraClob: ;
   ftVariant: ;
   ftInterface: ;
   ftIDispatch: ;
   ftGuid: ;
   ftFMTBcd: ;
   ftFixedWideChar: ;
   ftWideMemo: ;
   ftOraTimeStamp: ;
   ftOraInterval: ;
   ftLongWord: ;
   ftShortint: ;
   ftByte: ;
   ftExtended: ;
   ftConnection: ;
   ftParams: ;
   ftStream: ;
   ftTimeStampOffset: ;
   ftObject: ;
   ftSingle: ;
}
  end;
end;

class function TBindDataSet.GetInstance: IBindDataSet;
begin
   if not Assigned(FInstance) then
      FInstance := TBindDataSet.CreatePrivate;

   Result := FInstance;
end;

procedure TBindDataSet.SetAggregateFieldDefsObjectClass(ADataSet: TDataSet;
  AObject: TObject);
var
  LRttiType: TRttiType;
  LAggregates: TArray<TCustomAttribute>;
  LAggregate: TCustomAttribute;
begin
  LRttiType := FContext.GetType(AObject.ClassType);
  LAggregates :=  LRttiType.GetAggregateField;
  for LAggregate in LAggregates do
  begin
    TFieldSingleton.GetInstance.AddAggregateField(ADataSet,
                                                  AggregateField(LAggregate).FieldName,
                                                  AggregateField(LAggregate).Expression,
                                                  AggregateField(LAggregate).Alignment,
                                                  AggregateField(LAggregate).DisplayFormat);

  end;
end;

procedure TBindDataSet.SetCalcFieldDefsObjectClass(ADataSet: TDataSet; AObject: TObject);
var
  LCalcField: TCalcFieldMapping;
  LCalcFields: TCalcFieldMappingList;
begin
  LCalcFields := TMappingExplorer.GetInstance.GetMappingCalcField(AObject.ClassType);
  if LCalcFields <> nil then
  begin
    for LCalcField in LCalcFields do
    begin
      TFieldSingleton.GetInstance.AddCalcField(ADataSet,
                                               LCalcField.FieldName,
                                               LCalcField.FieldType,
                                               LCalcField.Size,
                                               LCalcField.Alignment,
                                               LCalcField.DisplayFormat);
    end;
  end;
end;

procedure TBindDataSet.SetDataDictionary(ADataSet: TDataSet; AObject: TObject);
var
  LColumn: TColumnMapping;
  LColumns: TColumnMappingList;
  LAttributo: TCustomAttribute;
  LFieldName: string;
begin
   LColumns := TMappingExplorer.GetInstance.GetMappingColumn(AObject.ClassType);
   for LColumn in LColumns do
   begin
     LFieldName := LColumn.ColumnName;
     if Assigned(TField(LColumn.PropertyRtti)) then
     begin
        LAttributo := LColumn.PropertyRtti.GetDictionary;
        if LAttributo = nil then
          Continue;

        /// DisplayLabel
        if Length(Dictionary(LAttributo).DisplayLabel) > 0 then
           ADataSet.FieldByName(LFieldName).DisplayLabel := Dictionary(LAttributo).DisplayLabel;

        /// ConstraintErrorMessage
        if Length(Dictionary(LAttributo).ConstraintErrorMessage) > 0 then
           ADataSet.FieldByName(LFieldName).ConstraintErrorMessage := Dictionary(LAttributo).ConstraintErrorMessage;

        /// DefaultExpression
        if Length(Dictionary(LAttributo).DefaultExpression) > 0 then
        begin
           if Dictionary(LAttributo).DefaultExpression = 'Date' then
              ADataSet.FieldByName(LFieldName).DefaultExpression := QuotedStr(DateToStr(Date))
           else
           if Dictionary(LAttributo).DefaultExpression = 'Now' then
              ADataSet.FieldByName(LFieldName).DefaultExpression := QuotedStr(DateTimeToStr(Now))
           else
              ADataSet.FieldByName(LFieldName).DefaultExpression := Dictionary(LAttributo).DefaultExpression;
        end;
        /// DisplayFormat
        if Length(Dictionary(LAttributo).DisplayFormat) > 0 then
           TDateField(ADataSet.FieldByName(LFieldName)).DisplayFormat := Dictionary(LAttributo).DisplayFormat;

        /// EditMask
        if Length(Dictionary(LAttributo).EditMask) > 0 then
           ADataSet.FieldByName(LFieldName).EditMask := Dictionary(LAttributo).EditMask;

        /// Alignment
        if Dictionary(LAttributo).Alignment in [taLeftJustify,taRightJustify,taCenter] then
           ADataSet.FieldByName(LFieldName).Alignment := Dictionary(LAttributo).Alignment;

        /// Origin
        ADataSet.FieldByName(LFieldName).Origin := AObject.GetTable.Name + '.' + LFieldName;
     end;
   end;
end;

procedure TBindDataSet.SetFieldToProperty(ADataSet: TDataSet; AObject: TObject);
var
  LColumn: TColumnMapping;
  LColumns: TColumnMappingList;
  LFieldName: string;
  LSetValueBlob: TBlob;
  LRttiType: TRttiType;
  LProperty: TRttiProperty;
begin
  LColumns := TMappingExplorer.GetInstance.GetMappingColumn(AObject.ClassType);
  for LColumn in LColumns do
  begin
    /// <summary>
    /// Só passa valor à propriedade se ela estiver definida como escrita,
    /// propriedade definida como não escrita, é usada para campo calculado.
    /// <example>
    /// <code>
    /// function GetTotal: Double;
    /// property Total: Double read GetTotal;
    /// </code>
    /// <returns>Quantidade * Preco</returns>
    /// </example>
    /// </summary>
    if LColumn.PropertyRtti.IsWritable then
    begin
      LFieldName := LColumn.ColumnName;
      LProperty  := LColumn.PropertyRtti;
      LRttiType  := LProperty.PropertyType;
      if LRttiType.TypeKind in [tkString, tkUString] then
        LProperty.SetValue(AObject, ADataSet.FieldByName(LFieldName).AsString)
      else
      if LRttiType.TypeKind in [tkInteger] then
        LProperty.SetValue(AObject, ADataSet.FieldByName(LFieldName).AsInteger)
      else
      if LRttiType.TypeKind in [tkFloat] then
      begin
        /// TDateTime
        if LRttiType.Handle = TypeInfo(TDateTime) then
          LProperty.SetValue(AObject, ADataSet.FieldByName(LFieldName).AsDateTime)
        else
        /// TTime
        if LRttiType.Handle = TypeInfo(TTime) then
          LProperty.SetValue(AObject, ADataSet.FieldByName(LFieldName).AsDateTime)
        else
          LProperty.SetValue(AObject, ADataSet.FieldByName(LFieldName).AsCurrency)
      end
      else
      if LRttiType.TypeKind in [tkRecord] then
      begin
        if LProperty.IsNullable then /// Nullable
        begin
          if ADataSet.FieldByName(LFieldName).IsNull then
            Continue;
          LProperty.SetNullableValue(AObject,
                                     LRttiType.Handle,
                                     ADataSet.FieldByName(LFieldName).AsVariant);
        end
        else
        if LProperty.IsBlob then /// TBlob
        begin
          if ADataSet.FieldByName(LFieldName).IsBlob then
          begin
            if not ADataSet.FieldByName(LFieldName).IsNull then
            begin
              LSetValueBlob.SetBlobField(TBlobField(ADataSet.FieldByName(LFieldName)));
              LProperty.SetValue(AObject, TValue.From<TBlob>(LSetValueBlob));
            end;
          end
          else
            raise Exception.Create(Format('Column [%s] must have blob value',
                                  [ADataSet.FieldByName(LFieldName).FieldName]));
        end;
      end
      else
      if LRttiType.TypeKind in [tkEnumeration] then
      begin
        if LColumn.FieldType in [ftBoolean] then
          LProperty.SetValue(AObject,
                             ADataSet.FieldByName(LFieldName).AsBoolean)
        else
        if LColumn.FieldType in [ftFixedChar, ftString] then
          LProperty.SetValue(AObject,
                             LProperty.GetEnumStringValue(ADataSet.FieldByName(LFieldName).AsString))
        else
        if LColumn.FieldType in [ftInteger] then
          LProperty.SetValue(AObject,
                             LProperty.GetEnumIntegerValue(ADataSet.FieldByName(LFieldName).AsInteger))
        else
          raise Exception.Create('Invalid type. Type enumerator supported [ftBoolena,ftInteger,ftFixedChar,ftString]');
      end;
    end;
  end;
end;

procedure TBindDataSet.SetFieldToField(AResultSet: IDBResultSet; ADataSet: TDataSet);
var
  LFor: Integer;
  LFieldValue: Variant;
  LReadOnly: Boolean;
begin
  for LFor := 1 to ADataSet.Fields.Count -1 do
  begin
     if (ADataSet.Fields[LFor].FieldKind = fkData) and
        (ADataSet.Fields[LFor].FieldName <> cInternalField) then
     begin
        LReadOnly := ADataSet.Fields[LFor].ReadOnly;
        ADataSet.Fields[LFor].ReadOnly := False;
        try
          if ADataSet.Fields[LFor].IsBlob then
          begin
            LFieldValue := AResultSet.GetFieldValue(ADataSet.Fields[LFor].FieldName);
            if LFieldValue <> Null then
              ADataSet.Fields[LFor].AsBytes := LFieldValue;
          end
          else
            ADataSet.Fields[LFor].Value := AResultSet.GetFieldValue(ADataSet.Fields[LFor].FieldName);
        finally
          ADataSet.Fields[LFor].ReadOnly := LReadOnly;
        end;
     end;
  end;
end;

procedure TBindDataSet.SetInternalInitFieldDefsObjectClass(ADataSet: TDataSet; AObject: TObject);
var
  LColumn: TColumnMapping;
  LColumns: TColumnMappingList;
  LPrimaryKey: TPrimaryKeyMapping;
  LFor: Integer;
begin
  ADataSet.Close;
  ADataSet.FieldDefs.Clear;
  LColumns := TMappingExplorer.GetInstance.GetMappingColumn(AObject.ClassType);
  for LColumn in LColumns do
  begin
    if ADataSet.FindField(LColumn.ColumnName) = nil then
    begin
       TFieldSingleton.GetInstance.AddField(ADataSet,
                                            LColumn.ColumnName,
                                            LColumn.FieldType,
                                            LColumn.Size);
    end;
    /// IsWritable
    if not LColumn.PropertyRtti.IsWritable then
      ADataSet.FieldByName(LColumn.ColumnName).ReadOnly := True;
    /// IsJoinColumn
    if LColumn.IsJoinColumn then
      ADataSet.FieldByName(LColumn.ColumnName).ReadOnly := True;
    /// NotNull the restriction
    if LColumn.IsNotNull then
      ADataSet.FieldByName(LColumn.ColumnName).Required := True;
    /// Hidden the restriction
    if LColumn.IsHidden then
      ADataSet.FieldByName(LColumn.ColumnName).Visible := False;
  end;
  /// Trata AutoInc
  LPrimaryKey := TMappingExplorer.GetInstance.GetMappingPrimaryKey(AObject.ClassType);
  if LPrimaryKey <> nil then
  begin
    if LPrimaryKey.AutoIncrement then
    begin
      for LFor := 0 to LPrimaryKey.Columns.Count -1 do
        ADataSet.FieldByName(LPrimaryKey.Columns[LFor]).DefaultExpression := '-1';
    end;
  end;
  /// <summary>
  /// TField para controle interno ao Dataset
  /// </summary>
  TFieldSingleton.GetInstance.AddField(ADataSet, cInternalField, ftInteger);
  ADataSet.Fields[ADataSet.Fields.Count -1].DefaultExpression := '-1';
  ADataSet.Fields[ADataSet.Fields.Count -1].Visible := False;
  ADataSet.Fields[ADataSet.Fields.Count -1].Index   := 0;
  /// <summary>
  /// Adiciona Fields Calcs
  /// </summary>
  SetCalcFieldDefsObjectClass(ADataSet, AObject);
  /// <summary>
  /// Adicionar Fields Aggregates
  /// </summary>
  SetAggregateFieldDefsObjectClass(ADataSet, AObject);
end;

end.

