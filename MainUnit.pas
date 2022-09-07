unit MainUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, GR32_Image, ComCtrls,
  decTreeView, System.ImageList, Vcl.ImgList;

type
  TMainForm = class(TForm)
    Tree: TdecTreeView;
    ImageList1: TImageList;
    Button4: TButton;
    StepButton: TButton;
    Button6: TButton;
    GroupBox1: TGroupBox;
    Button1: TButton;
    Edit1: TEdit;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button4Click(Sender: TObject);
    procedure StepButtonClick(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure TreeKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TreeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
    ExecutionStoped: Boolean;
    GotoNextLevel: Boolean;
    ExecutionFinished: Boolean;
    ImediateRun: Boolean;
    procedure CloseProgram(var msg: TMessage); message WM_USER+1;
    procedure AddNodes(NodePerDepth: Integer; MaxDepth: Integer); overload;
    procedure AddNodes(Node: TTreeNode; NodeCount: Integer; Depth: Integer); overload;
    function NegaMaxAlphaBeta(Node: TTreeNode; Depth: Integer; Alpha: Integer; Beta: Integer): Integer;
    procedure UpdateNodeDebugValues(Node: TTreeNode; Alpha,Beta,Res: Integer);
    procedure WaitForNextStep;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.AddNodes(NodePerDepth, MaxDepth: Integer);
var
  RootNode: TTreeNode;
begin
  RootNode := Tree.Items.AddChild(nil,'α = ?'+#13#10+'β = ?'+#13#10+'V = ?');
  AddNodes(RootNode,NodePerDepth, MaxDepth-1);
  RootNode.Expand(True);
 // RootNode.ImageIndex := 1;

end;

procedure TMainForm.AddNodes(Node: TTreeNode; NodeCount: Integer; Depth: Integer);
var
  i: Integer;
  CurNode: TTreeNode;
  ActualNodeCount: Integer;
begin
  if Depth = 3 then
    ActualNodeCount := NodeCount -1
  else
    ActualNodeCount := NodeCount;
  for i := 0 to ActualNodeCount - 1 do
    if Depth = 0 then
      Tree.Items.AddChild(Node,IntToStr(Random(12)-3))
    else
    begin
      CurNode := Tree.Items.AddChild(Node,'α = ?'+#13#10+'β = ?'+#13#10+'V = ?');
      AddNodes(CurNode,NodeCount,Depth-1);
      CurNode.Expand(True);
    end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  RandSeed := StrToInt(Edit1.Text);
  Tree.Items.Clear;
  AddNodes(3,4);
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
  Randomize;
  Edit1.Text := IntToStr(RandSeed);
  Tree.Items.Clear;
  AddNodes(3,4);
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
  ExecutionStoped := False;
  GotoNextLevel := True;
  //Tree.Items.GetFirstNode.ImageIndex := 1;
  Tree.Refresh;
  //Caption := BoolToStr(Tree.Items.GetFirstNode.IsFirstNode);
  //WaitForNextStep;
  NegaMaxAlphaBeta(Tree.Items.GetFirstNode,4,-1000,1000);
  ImediateRun := False;
end;

procedure TMainForm.StepButtonClick(Sender: TObject);
begin
  GotoNextLevel := True;
end;

procedure TMainForm.Button6Click(Sender: TObject);
begin
  ImediateRun := True;
  GotoNextLevel := True;
end;

procedure TMainForm.CloseProgram(var msg: TMessage);
begin
  Close;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not ExecutionStoped then
  begin
    ExecutionStoped := True;
    CanClose := False;
    PostMessage(Handle,WM_USER+1,0,0);
  end
  else
    CanClose := True;
end;

procedure TMainForm.UpdateNodeDebugValues(Node: TTreeNode; Alpha, Beta,
  Res: Integer);
begin
  Node.Text := 'α = '+IntToStr(Alpha)+#13#10+'β = '+IntToStr(Beta)+#13#10+'V = ';
  if Res <>-30 then
    Node.Text := Node.Text + IntToStr(Res)
  else
    Node.Text := Node.Text + '?'
end;

procedure TMainForm.WaitForNextStep;
begin
  GotoNextLevel := False;
  while not (ExecutionStoped or GotoNextLevel) do
  begin
    Application.ProcessMessages;
    Sleep(10);
  end;
end;

function TMainForm.NegaMaxAlphaBeta(Node: TTreeNode; Depth, Alpha,
  Beta: Integer): Integer;
var
  i,ChildCount: Integer;
  CurScore,BestScore: Integer;
begin
  Node.ImageIndex := 1;
  if not ImediateRun then WaitForNextStep;
  if Depth = 0 then
  begin
    Result := StrToInt(Node.Text);
    Node.ImageIndex := 2;
    Exit;
  end;
  UpdateNodeDebugValues(Node,Alpha,Beta,-30);
  BestScore := -MAXINT;
  if not ImediateRun then WaitForNextStep;
  for i := Node.Count - 1 downto 0 do
  begin
    Node.ImageIndex := 2;
    CurScore := -NegaMaxAlphaBeta(Node.Item[i],Depth-1,-Beta,-Alpha);
    Node.ImageIndex := 1;
    if CurScore>BestScore then
      BestScore := CurScore;
    if BestScore>Alpha then
      Alpha := BestScore;
    if BestScore>=Beta then
      break;
    UpdateNodeDebugValues(Node,Alpha,Beta,BestScore);
    if not ImediateRun then WaitForNextStep;
  end;
  Result := BestScore;
  UpdateNodeDebugValues(Node,Alpha,Beta,Result);
  if not ImediateRun then WaitForNextStep;
  Node.ImageIndex := 2;
end;

procedure TMainForm.TreeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_F8 then
    StepButtonClick(Self);
end;

procedure TMainForm.TreeKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

end;

//  Seems to be wrong implementation
//function TMainForm.NegaMaxAlphaBeta(Node: TTreeNode; Depth, Alpha,
//  Beta: Integer): Integer;
//var
//  i,ChildCount,Score: Integer;
//begin
//  Node.ImageIndex := 1;
//  if not ImediateRun then WaitForNextStep;
//  if Depth = 0 then
//  begin
//    Result := StrToInt(Node.Text);
//    Node.ImageIndex := 2;
//    Exit;
//  end;
//  UpdateNodeDebugValues(Node,Alpha,Beta,-30);
//  if not ImediateRun then WaitForNextStep;
//  for i := Node.Count - 1 downto 0 do
//  begin
//    Node.ImageIndex := 2;
//    Score := -NegaMaxAlphaBeta(Node.Item[i],Depth-1,-Beta,-Alpha);
//    Node.ImageIndex := 1;
//    if Score>=Beta then
//    begin
//      Result := Beta;
//      Node.ImageIndex := 2;
//      UpdateNodeDebugValues(Node,Alpha,Beta,Result);
//      Exit;
//    end;
//    if Score>Alpha then
//      Alpha := Score;
//    UpdateNodeDebugValues(Node,Alpha,Beta,Score);
//    if not ImediateRun then WaitForNextStep;
//  end;
//  Result := Alpha;
//  UpdateNodeDebugValues(Node,Alpha,Beta,Result);
//  Node.ImageIndex := 2;
//end;

end.
