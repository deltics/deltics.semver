
program test;

{$APPTYPE CONSOLE}

  uses
  Deltics.Smoketest,
  CustomAssertions in 'CustomAssertions.pas',
  Deltics.SemVer in '..\src\Deltics.SemVer.pas';

type
    Tests = class(TTest)
      procedure ReleaseSemVerIsCorrectlyParsed;
      procedure ReleaseSemVerWithHigherMajorIsNewer;
      procedure ReleaseSemVerWithHigherMinorIsNewer;
      procedure ReleaseSemVerWithHigherPatchIsNewer;
      procedure ReleaseSemVerIsNewerThanPreReleaseSemver;
      procedure LaterPreReleaseSemVerIsNewerThanEarlierPreReleaseSemver;
    end;


{ Tests }

  procedure Tests.ReleaseSemVerIsCorrectlyParsed;
  var
    v: ISemVer;
  begin
    v := TSemVer.Create('1.2.3');

    Test('{v}', [v.AsString]).Assert(v).Equals(1, 2, 3);
    Test('Identifiers.Count').Assert(v.Identifiers.Count).Equals(0);
    Test('Metadata.Count').Assert(v.Metadata.Count).Equals(0);
  end;


  procedure Tests.ReleaseSemVerWithHigherMajorIsNewer;
  var
    a, b: ISemVer;
  begin
    a := TSemVer.Create('2.0.0');
    b := TSemVer.Create('1.0.0');

    Test('{a}.IsNewerThan({b})', [a.AsString, b.AsString]).Assert(a).IsNewerThan(b);
  end;


  procedure Tests.ReleaseSemVerWithHigherMinorIsNewer;
  var
    a, b: ISemVer;
  begin
    a := TSemVer.Create('1.1.0');
    b := TSemVer.Create('1.0.0');

    Test('{a}.IsNewerThan({b})', [a.AsString, b.AsString]).Assert(a).IsNewerThan(b);
  end;


  procedure Tests.ReleaseSemVerWithHigherPatchIsNewer;
  var
    a, b: ISemVer;
  begin
    a := TSemVer.Create('1.0.1');
    b := TSemVer.Create('1.0.0');

    Test('{a}.IsNewerThan({b})', [a.AsString, b.AsString]).Assert(a).IsNewerThan(b);
  end;


  procedure Tests.ReleaseSemVerIsNewerThanPreReleaseSemver;
  var
    a, b: ISemVer;
  begin
    a := TSemVer.Create('1.2.3');
    b := TSemVer.Create('1.2.3-beta');

    Test('{a}.IsNewerThan({b})', [a.AsString, b.AsString]).Assert(a).IsNewerThan(b);
  end;


  procedure Tests.LaterPreReleaseSemVerIsNewerThanEarlierPreReleaseSemver;
  var
    a, b: ISemVer;
  begin
    a := TSemVer.Create('1.2.3-beta.17');
    b := TSemVer.Create('1.2.3-beta.12');

    Test('{a}.IsNewerThan({b})', [a.AsString, b.AsString]).Assert(a).IsNewerThan(b);
  end;






begin
  TestRun.Environment := DELPHI_VERSION_NAME;
  TestRun.Test(Tests);
end.
