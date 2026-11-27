package pg

import (
	"testing"
	"unicode/utf16"
)

func TestSplit(t *testing.T) {
	sql := "select 1;\n-- only a comment;\n" +
		"select 'a;b', \"we;ird\", E'x\\';y';\n" +
		"create function f() returns int as $body$ begin return 1; end $body$ language plpgsql;\n" +
		"/* outer /* nested ; */ still */ select $$;$$  ;  \n" +
		"select 'тест' -- trailing"
	got := Split(sql)
	want := []string{
		"select 1",
		"-- only a comment;\nselect 'a;b', \"we;ird\", E'x\\';y'",
		"create function f() returns int as $body$ begin return 1; end $body$ language plpgsql",
		"/* outer /* nested ; */ still */ select $$;$$",
		"select 'тест' -- trailing",
	}
	if len(got) != len(want) {
		for _, g := range got {
			t.Logf("%q", g.Text)
		}
		t.Fatalf("got %d statements, want %d", len(got), len(want))
	}
	u := utf16.Encode([]rune(sql))
	for i, g := range got {
		if g.Text != want[i] {
			t.Errorf("%d: %q, want %q", i, g.Text, want[i])
		}
		if s := string(utf16.Decode(u[g.Start16:g.End16])); s != g.Text {
			t.Errorf("%d: utf16 range gives %q", i, s)
		}
	}
	// Cursor inside, right after, on a blank line after, before the first.
	if s, _ := At(got, 3); s.Text != "select 1" {
		t.Errorf("at 3: %q", s.Text)
	}
	if s, _ := At(got, got[0].End16+1); s.Text != "select 1" {
		t.Errorf("after ;: %q", s.Text)
	}
	if s, _ := At(got, len(u)); s.Text != want[4] {
		t.Errorf("at end: %q", s.Text)
	}
	if len(Split("  -- nothing\n /* here */ ")) != 0 {
		t.Error("comments only should give nothing")
	}
	if got := Split("select $1, a$b from t; select 2"); len(got) != 2 {
		t.Errorf("params and $ inside identifiers: %d statements", len(got))
	}
}
