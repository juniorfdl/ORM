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

{$INCLUDE ..\ormbr.inc}

unit ormbr.session.datasnap;

interface

uses
  DB,
  Rtti,
  TypInfo,
  Classes,
  Variants,
  SysUtils,
  Generics.Collections,
  REST.Client,
  /// orm
  ormbr.dataset.bind,
  ormbr.mapping.classes,
  ormbr.container.dataset,
  ormbr.mapping.explorerstrategy,
  ormbr.dataset.base.adapter,
  ormbr.session.abstract;

type
  /// <summary>
  /// M - Sessão RESTFull
  /// </summary>
  TDataSnapSessionDataSet<M: class, constructor> = class(TSessionAbstract<M>)
  private
    FOwner: TDataSetBaseAdapter<M>;
    FRESTResponse: TRESTResponse;
    FRESTRequest: TRESTRequest;
    FRESTClient: TRESTClient;
  protected
  public
    constructor Create(const AOwner: TDataSetBaseAdapter<M>; const APageSize: Integer = -1); overload;
    destructor Destroy; override;
    procedure Insert(const AObjectList: TObjectList<M>); overload;
    procedure Update(const AObjectList: TObjectList<M>); overload;
    procedure Delete(const AObject: M); overload; override;
    procedure Delete(const AID: Integer); overload; override;
    procedure NextPacket(const AObjectList: TObjectList<M>); overload; override;
    procedure OpenID(const AID: Variant);
    procedure OpenSQL(const ASQL: string); override;
    procedure OpenWhere(const AWhere: string; const AOrderBy: string = '');
    procedure NextPacket; overload;
    procedure ModifyFieldsCompare(const AKey: string; const AObjectSource, AObjectUpdate: TObject); override;
    procedure RefreshRecord(const AColumnName: string);
    function Find: TObjectList<M>; overload; override;
    function Find(const AID: Integer): M; overload; override;
    function Find(const AID: String): M; overload; override;
    function FindWhere(const AWhere: string; const AOrderBy: string = ''): TObjectList<M>; override;
    function ModifiedFields: TDictionary<string, TList<string>>; override;
    function DeleteList: TObjectList<M>; override;
    function FetchingRecords: Boolean;
    function Explorer: IMappingExplorerStrategy;
  end;

implementation

uses
  REST.Types,
  IPPeerClient,
  DBXJSONReflect,
  System.JSON,
  ormbr.rest.json,
  ormbr.rtti.helper,
  ormbr.restdataset.adapter,
  ormbr.objects.helper,
  ormbr.jsonutils.datasnap;

{ TDataSnapSessionDataSet<M> }

constructor TDataSnapSessionDataSet<M>.Create(const AOwner: TDataSetBaseAdapter<M>;
  const APageSize: Integer = -1);
begin
  inherited Create(APageSize);
  FOwner := AOwner;
  FRESTRequest := TRESTRequest.Create(nil);
  FRESTResponse := TRESTResponse.Create(nil);
  FRESTClient := TRESTClient.Create('http://127.0.0.1:80/datasnap/rest/tormbr');
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.Response := FRESTResponse;
  FRESTResponse.RootElement := 'result';
end;

destructor TDataSnapSessionDataSet<M>.Destroy;
begin
  FRESTClient.Free;
  FRESTResponse.Free;
  FRESTRequest.Free;
  inherited;
end;

procedure TDataSnapSessionDataSet<M>.Delete(const AObject: M);
begin

end;

procedure TDataSnapSessionDataSet<M>.Delete(const AID: Integer);
begin
  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/master/{ID}';
  FRESTRequest.Method := TRESTRequestMethod.rmDELETE;
  FRESTRequest.Params.AddUrlSegment('ID', IntToStr(AID));
  FRESTRequest.Execute;
end;

function TDataSnapSessionDataSet<M>.FetchingRecords: Boolean;
begin

end;

function TDataSnapSessionDataSet<M>.FindWhere(const AWhere, AOrderBy: string): TObjectList<M>;
var
  LJSON: string;
begin
  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/master/{WHERE}/{ORDERBY}';
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  FRESTRequest.Params.AddUrlSegment('WHERE', AWhere);
  FRESTRequest.Params.AddUrlSegment('ORDERBY', AOrderBy);
  FRESTRequest.Execute;

  LJSON := TJSONArray(FRESTRequest.Response.JSONValue).Items[0].ToJSON;
  /// <summary>
  /// Transforma o JSON recebido populando o objeto
  /// </summary>
  Result := TORMBrJson.JsonToObjectList<M>(LJSON);
end;

function TDataSnapSessionDataSet<M>.Find(const AID: Integer): M;
begin
  /// <summary>
  /// Transforma o JSON recebido populando o objeto
  /// </summary>
  Result := Find(IntToStr(AID));
end;

function TDataSnapSessionDataSet<M>.Find(const AID: string): M;
var
  LJSON: string;
begin
  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/master/{ID}';
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  FRESTRequest.Params.AddUrlSegment('ID', AID);
  FRESTRequest.Execute;

  LJSON := TJSONArray(TJSONArray(FRESTRequest.Response.JSONValue).Items[0]).Items[0].ToJSON;
  /// <summary>
  /// Transforma o JSON recebido populando o objeto
  /// </summary>
  Result := TORMBrJson.JsonToObject<M>(LJSON);
end;

function TDataSnapSessionDataSet<M>.Find: TObjectList<M>;
var
  LJSON: string;
begin
  FRESTRequest.ResetToDefaults;
  FRESTRequest.Resource := '/master/{ID}';
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  FRESTRequest.Params.AddUrlSegment('ID', '0');
  FRESTRequest.Execute;

  LJSON := TJSONArray(FRESTRequest.Response.JSONValue).Items[0].ToJSON;
  /// <summary>
  /// Transforma o JSON recebido populando o objeto
  /// </summary>
  Result := TORMBrJson.JsonToObjectList<M>(LJSON);
end;

procedure TDataSnapSessionDataSet<M>.Insert(const AObjectList: TObjectList<M>);
var
  FJSON: TJSONArray;
begin
  FJSON := TORMBrJSONUtil.JSONStringToJSONArray<M>(AObjectList);
  try
    FRESTRequest.ResetToDefaults;
    FRESTRequest.Resource := '/master';
    FRESTRequest.Method := TRESTRequestMethod.rmPUT;
    {$IFDEF DELPHI22_UP}
    FRESTRequest.AddBody(FJSON.ToJSON, ContentTypeFromString('application/json'));
    {$ELSE}
    FRESTRequest.Body.Add(FJSON.ToJSON, ContentTypeFromString('application/json'));
    {$ENDIF}
    FRESTRequest.Execute;
  finally
    FJSON.Free;
  end;
end;

procedure TDataSnapSessionDataSet<M>.Update(const AObjectList: TObjectList<M>);
var
  FJSON: TJSONArray;
begin
  FJSON := TORMBrJSONUtil.JSONStringToJSONArray<M>(AObjectList);
  try
    FRESTRequest.ResetToDefaults;
    FRESTRequest.Resource := '/master';
    FRESTRequest.Method := TRESTRequestMethod.rmPOST;
    {$IFDEF DELPHI22_UP}
    FRESTRequest.AddBody(FJSON.ToJSON, ContentTypeFromString('application/json'));
    {$ELSE}
    FRESTRequest.Body.Add(FJSON.ToJSON, ContentTypeFromString('application/json'));
    {$ENDIF}
    FRESTRequest.Execute;
  finally
    FJSON.Free;
  end;
end;

procedure TDataSnapSessionDataSet<M>.ModifyFieldsCompare(const AKey: string;
  const AObjectSource, AObjectUpdate: TObject);
begin
  inherited ModifyFieldsCompare(AKey, AObjectSource, AObjectUpdate);
end;

procedure TDataSnapSessionDataSet<M>.NextPacket;
begin

end;

procedure TDataSnapSessionDataSet<M>.NextPacket(const AObjectList: TObjectList<M>);
begin

end;

procedure TDataSnapSessionDataSet<M>.OpenID(const AID: Variant);
var
  LObject: M;
begin
  LObject := Find(Integer(AID));
  if LObject <> nil then
  begin
    try
      TRESTDataSetAdapter<M>(FOwner).PopularDataSet(LObject);
    finally
      LObject.Free;
    end;
  end;
end;

procedure TDataSnapSessionDataSet<M>.OpenSQL(const ASQL: string);
var
  LObjectList: TObjectList<M>;
begin
  if ASQL = '' then
    LObjectList := Find
  else
    LObjectList := FindSQL(ASQL);
  /// <summary>
  /// Popula do DataSet
  /// </summary>
  if LObjectList <> nil then
  begin
    try
      TRESTDataSetAdapter<M>(FOwner).PopularDataSetList(LObjectList);
    finally
      LObjectList.Clear;
      LObjectList.Free;
    end;
  end;
end;

procedure TDataSnapSessionDataSet<M>.OpenWhere(const AWhere, AOrderBy: string);
var
  LObjectList: TObjectList<M>;
begin
  LObjectList := FindWhere(AWhere, AOrderBy);
  /// <summary>
  /// Popula do DataSet
  /// </summary>
  if LObjectList <> nil then
  begin
    try
      TRESTDataSetAdapter<M>(FOwner).PopularDataSetList(LObjectList);
    finally
      LObjectList.Clear;
      LObjectList.Free;
    end;
  end;
end;

procedure TDataSnapSessionDataSet<M>.RefreshRecord(const AColumnName: string);
begin

end;

function TDataSnapSessionDataSet<M>.ModifiedFields: TDictionary<string, TList<string>>;
begin
  Result := inherited ModifiedFields;
end;

function TDataSnapSessionDataSet<M>.DeleteList: TObjectList<M>;
begin
  Result := inherited DeleteList;
end;

function TDataSnapSessionDataSet<M>.Explorer: IMappingExplorerStrategy;
begin
  Result := inherited Explorer;
end;

end.
