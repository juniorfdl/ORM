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

  ORM Brasil é um ORM simples e descomplicado para quem utiliza Delphi.
}

unit ormbr.mapping.rttiutils;

interface

uses
  Classes,
  SysUtils,
  Rtti,
  DB,
  TypInfo,
  Math,
  StrUtils,
  Types,
  Variants,
  Generics.Collections,
  /// orm
  ormbr.mapping.attributes,
  ormbr.mapping.classes,
  ormbr.types.mapping;

type
  IRttiSingleton = interface
    ['{AF40524E-2027-46C3-AAAE-5F4267689CD8}']
    function GetRttiType(AClass: TClass): TRttiType;
//    function RunValidade(AClass: TClass): Boolean;
    function MethodCall(AObject: TObject; AMethodName: string; const AParameters: array of TValue): TValue;
    function Clone(AObject: TObject): TObject;
    function CreateObject(ARttiType: TRttiType): TObject;
    procedure CopyObject(ASourceObject, ATargetObject: TObject);
  end;

  TRttiSingleton = class(TInterfacedObject, IRttiSingleton)
  private
  class var
    FInstance: IRttiSingleton;
  private
    FContext: TRttiContext;
    constructor CreatePrivate;
  public
    { Public declarations }
    constructor Create;
    destructor Destroy; override;
    class function GetInstance: IRttiSingleton;
    function GetRttiType(AClass: TClass): TRttiType;
//    function RunValidade(AClass: TClass): Boolean;
    function MethodCall(AObject: TObject; AMethodName: string; const AParameters: array of TValue): TValue;
    function Clone(AObject: TObject): TObject;
    function CreateObject(ARttiType: TRttiType): TObject;
    procedure CopyObject(ASourceObject, ATargetObject: TObject);
  end;

implementation

uses
  ormbr.mapping.explorer,
  ormbr.rtti.helper;

{ TRttiSingleton }

function TRttiSingleton.Clone(AObject: TObject): TObject;
var
  _ARttiType: TRttiType;
  Field: TRttiField;
  master, cloned: TObject;
  Src: TObject;
  sourceStream: TStream;
  SavedPosition: Int64;
  targetStream: TStream;
  targetCollection: TObjectList<TObject>;
  sourceCollection: TObjectList<TObject>;
  I: Integer;
  sourceObject: TObject;
  targetObject: TObject;
begin
  Result := nil;
  if not Assigned(AObject) then
    Exit;

  _ARttiType := FContext.GetType(AObject.ClassType);
  cloned := CreateObject(_ARttiType);
  master := AObject;
  for Field in _ARttiType.GetFields do
  begin
    if not Field.FieldType.IsInstance then
      Field.SetValue(cloned, Field.GetValue(master))
    else
    begin
      Src := Field.GetValue(AObject).AsObject;
      if Src is TStream then
      begin
        sourceStream := TStream(Src);
        SavedPosition := sourceStream.Position;
        sourceStream.Position := 0;
//        if Field.GetValue(cloned).IsEmpty then
        if Field.GetValue(cloned).AsType<Variant> = Null then
        begin
          targetStream := TMemoryStream.Create;
          Field.SetValue(cloned, targetStream);
        end
        else
          targetStream := Field.GetValue(cloned).AsObject as TStream;
        targetStream.Position := 0;
        targetStream.CopyFrom(sourceStream, sourceStream.Size);
        targetStream.Position := SavedPosition;
        sourceStream.Position := SavedPosition;
      end
      else if Src is TObjectList<TObject> then
      begin
        sourceCollection := TObjectList<TObject>(Src);
//        if Field.GetValue(cloned).IsEmpty then
        if Field.GetValue(cloned).AsType<Variant> = Null then
        begin
          targetCollection := TObjectList<TObject>.Create;
          Field.SetValue(cloned, targetCollection);
        end
        else
          targetCollection := Field.GetValue(cloned).AsObject as TObjectList<TObject>;
        for I := 0 to sourceCollection.Count - 1 do
        begin
          targetCollection.Add(Clone(sourceCollection[I]));
        end;
      end
      else
      begin
        sourceObject := Src;

//        if Field.GetValue(cloned).IsEmpty then
        if Field.GetValue(cloned).AsType<Variant> = Null then
        begin
          targetObject := Clone(sourceObject);
          Field.SetValue(cloned, targetObject);
        end
        else
        begin
          targetObject := Field.GetValue(cloned).AsObject;
          CopyObject(sourceObject, targetObject);
        end;
        Field.SetValue(cloned, targetObject);
      end;
    end;
  end;
  Result := cloned;
end;

procedure TRttiSingleton.CopyObject(ASourceObject, ATargetObject: TObject);
var
  _ARttiType: TRttiType;
  Field: TRttiField;
  master, cloned: TObject;
  Src: TObject;
  sourceStream: TStream;
  SavedPosition: Int64;
  targetStream: TStream;
//  targetCollection: IWrappedList;
//  sourceCollection: IWrappedList;
  I: Integer;
  sourceObject: TObject;
  targetObject: TObject;
  Tar: TObject;
begin
  if not Assigned(ATargetObject) then
    Exit;

  _ARttiType := FContext.GetType(ASourceObject.ClassType);
  cloned := ATargetObject;
  master := ASourceObject;
  for Field in _ARttiType.GetFields do
  begin
    if not Field.FieldType.IsInstance then
      Field.SetValue(cloned, Field.GetValue(master))
    else
    begin
      Src := Field.GetValue(ASourceObject).AsObject;
      if Src is TStream then
      begin
        sourceStream := TStream(Src);
        SavedPosition := sourceStream.Position;
        sourceStream.Position := 0;
//        if Field.GetValue(cloned).IsEmpty then
        if Field.GetValue(cloned).AsType<Variant> = Null then
        begin
          targetStream := TMemoryStream.Create;
          Field.SetValue(cloned, targetStream);
        end
        else
          targetStream := Field.GetValue(cloned).AsObject as TStream;
        targetStream.Position := 0;
        targetStream.CopyFrom(sourceStream, sourceStream.Size);
        targetStream.Position := SavedPosition;
        sourceStream.Position := SavedPosition;
      end
//      else if TDuckTypedList.CanBeWrappedAsList(Src) then
//      begin
//        sourceCollection := WrapAsList(Src);
//        Tar := Field.GetValue(cloned).AsObject;
//        if Assigned(Tar) then
//        begin
//          targetCollection := WrapAsList(Tar);
//          targetCollection.Clear;
//          for I := 0 to sourceCollection.Count - 1 do
//            targetCollection.Add(TRTTIUtils.Clone(sourceCollection.GetItem(I)));
//        end;
//      end
      else
      begin
        sourceObject := Src;

//        if Field.GetValue(cloned).IsEmpty then
        if Field.GetValue(cloned).AsType<Variant> = Null then
        begin
          targetObject := Clone(sourceObject);
          Field.SetValue(cloned, targetObject);
        end
        else
        begin
          targetObject := Field.GetValue(cloned).AsObject;
          CopyObject(sourceObject, targetObject);
        end;
      end;
    end;
  end;
end;

function TRttiSingleton.CreateObject(ARttiType: TRttiType): TObject;
var
  Method: TRttiMethod;
  metaClass: TClass;
begin
  { First solution, clear and slow }
  metaClass := nil;
  Method := nil;
  for Method in ARttiType.GetMethods do
    if Method.HasExtendedInfo and Method.IsConstructor then
      if Length(Method.GetParameters) = 0 then
      begin
        metaClass := ARttiType.AsInstance.MetaclassType;
        Break;
      end;
  if Assigned(metaClass) then
    Result := Method.Invoke(metaClass, []).AsObject
  else
    raise Exception.Create('Cannot find a propert constructor for ' + ARttiType.ToString);

  { Second solution, dirty and fast }
  // Result := TObject(ARttiType.GetMethod('Create')
  // .Invoke(ARttiType.AsInstance.MetaclassType, []).AsObject);
end;

constructor TRttiSingleton.Create;
begin
   raise Exception.Create('Para usar o MappingEntity use o método TRttiSingleton.GetInstance()');
end;

constructor TRttiSingleton.CreatePrivate;
begin
   inherited;
   FContext := TRttiContext.Create;
end;

destructor TRttiSingleton.Destroy;
begin
  FContext.Free;
  inherited;
end;

function TRttiSingleton.GetRttiType(AClass: TClass): TRttiType;
begin
  Result := FContext.GetType(AClass);
end;

class function TRttiSingleton.GetInstance: IRttiSingleton;
begin
  if not Assigned(FInstance) then
    FInstance := TRttiSingleton.CreatePrivate;
   Result := FInstance;
end;

//function TRttiSingleton.RunValidade(AClass: TClass): Boolean;
//var
//  LColumn: TColumnMapping;
//  LColumns: TColumnMappingList;
//  LAttribute: TCustomAttribute;
//begin
//  Result := False;
//  LColumns := TMappingExplorer.GetInstance.GetMappingColumn(AClass);
//  for LColumn in LColumns do
//  begin
//     /// <summary>
//     /// Valida se o valor é NULO
//     /// </summary>
//     LAttribute := LColumn.PropertyRtti.GetNotNullConstraint;
//     if LAttribute <> nil then
//       NotNullConstraint(LAttribute).Validate(LColumn.ColumnName, LColumn.PropertyRtti.GetNullableValue(AClass));
//
//     /// <summary>
//     /// Valida se o valor é menor que ZERO
//     /// </summary>
//     LAttribute := LColumn.PropertyRtti.GetZeroConstraint;
//     if LAttribute <> nil then
//        ZeroConstraint(LAttribute).Validate(LColumn.ColumnName, LColumn.PropertyRtti.GetNullableValue(AClass));
//  end;
//  Result := True;
//end;

function TRttiSingleton.MethodCall(AObject: TObject; AMethodName: string;
  const AParameters: array of TValue): TValue;
var
  LRttiType: TRttiType;
  LMethod: TRttiMethod;
begin
  LRttiType := GetRttiType(AObject.ClassType);
  LMethod   := LRttiType.GetMethod(AMethodName);
  if Assigned(LMethod) then
     Result := LMethod.Invoke(AObject, AParameters)
  else
     raise Exception.CreateFmt('Cannot find method "%s" in the object',[AMethodName]);
end;

end.

