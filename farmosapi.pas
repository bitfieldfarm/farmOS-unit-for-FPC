unit farmosapi;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, FPHTTPClient, httpdefs, opensslsockets, fpjson, jsonparser;

function GetOAuthToken(out Token: string): Boolean;
function GetAccessTokenValue(const JsonString: string): string;
function GetFarmOS(const Endpoint, AccessToken :string; out StatusCode: Integer; out JsonResponse: string): Boolean;
function PostFarmOS(const Endpoint, AccessToken, JsonData: string): Integer;



implementation

{$i 'settings.inc'}
// Settings.inc should have following constants
//const
//    ClientID = 'farm';
//    BaseUrl = 'https://your.farmos.url/';
//    UserName = '';
//    Password = '';
//    ClientSecret = 'client-secret';
//    Scope = 'farm_manager';


function GetOAuthToken(out Token: string): Boolean;
var
  Params: TStringList;
  ResponseStream: TStringStream;
  HttpClient: TFPHTTPClient;
  JsonResponse: TJSONObject;
begin
  Result := False; // Assume failure
  Token := '';     // Initialize output parameter

  Params := TStringList.Create;
  ResponseStream := TStringStream.Create;
  HttpClient := TFPHTTPClient.Create(nil);
  JsonResponse := TJSONObject.Create;

  try
    // Legg til nødvendige parametere som brukernavn, passord, etc.
    Params.Add('grant_type=password');
    Params.Add('client_id=' + ClientID);
    Params.Add('username=' + UserName);
    Params.Add('password=' + Password);
    Params.Add('scope=' + Scope);
    Params.Add('client_secret=' + ClientSecret);

    try
      // Send en forespørsel for å få AccessToken og RefreshToken
      HttpClient.FormPost(BaseUrl + 'oauth/token', Params, ResponseStream);

      // Parse JSON-strengen
      JsonResponse := TJSONObject(GetJSON(ResponseStream.DataString));

      // Hent ut access token fra JSON
      Token := JsonResponse.Get('access_token', '');

      Result := True; // Set success flag
    except
      on E: Exception do
        writeln('Feil under HTTP-forespørsel: ', E.Message);
    end;
  finally
    Params.Free;
    ResponseStream.Free;
    HttpClient.Free;
    JsonResponse.Free;
  end;
end;


function GetAccessTokenValue(const JsonString: string): string;
var
  JsonData: TJSONData;
begin
  Result := '';
  try
    JsonData := GetJSON(JsonString);
    if Assigned(JsonData) and (JsonData.JSONType = jtObject) then
    begin
      Result := JsonData.FindPath('access_token').AsString;
    end;
  finally
    JsonData.Free;
  end;
end;


//.......................
//GET data from farmos API.
//Endpoint example = api/log/activity
function GetFarmOS(const Endpoint, AccessToken :string; out StatusCode: Integer; out JsonResponse: string): Boolean;
var
  ApiUrl: string;
  ResponseStream: TMemoryStream;
  HttpClient: TFPHTTPClient;
begin
  Result := False; // Assume failure
  ApiUrl := BaseUrl + Endpoint;

  ResponseStream := TMemoryStream.Create;

  HttpClient := TFPHTTPClient.Create(nil);

  try
    HttpClient.RequestHeaders.Clear;
    HttpClient.AddHeader('Authorization', 'Bearer ' + AccessToken);

    try
      HttpClient.Get(ApiUrl, ResponseStream);
      StatusCode := HttpClient.ResponseStatusCode;

      ResponseStream.Position := 0;
      SetLength(JsonResponse, ResponseStream.Size);
      ResponseStream.ReadBuffer(JsonResponse[1], Length(JsonResponse));

      Result := True;
    except
      on E: EHTTPClient do
        ; // Handle the exception if needed
    end;
  finally
    ResponseStream.Free;
    HttpClient.Free;
  end;
end;


//POSS data to farmos API.
//Endpoint example = api/log/activity
function PostFarmOS(const Endpoint, AccessToken, JsonData: string): Integer;
var
  Client: TFPHttpClient;
  Response: TStringStream;
begin
  Result := 0;

  try
    Client := TFPHttpClient.Create(nil);
    Response := TStringStream.Create;

    try
      Client.AddHeader('Authorization', 'Bearer ' + AccessToken);
      Client.AddHeader('Content-Type', 'application/vnd.api+json');
      Client.AddHeader('Accept', 'application/json');
      Client.AllowRedirect := true;
      // HTTP POST
      try
        Client.RequestBody := TRawByteStringStream.Create(JsonData);
        Client.Post(Endpoint, Response);
        Result := Client.ResponseStatusCode;

      except
        Result := 0; // missing error handling
      end;
    finally
      // cleanup
      Client.RequestBody.Free;
      Client.Free;
      Response.Free;
    end;
  except
    Result := 0 // missing error handling;
  end;
end;



end.

