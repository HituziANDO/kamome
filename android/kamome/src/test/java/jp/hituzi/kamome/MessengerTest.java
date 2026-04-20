package jp.hituzi.kamome;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class MessengerTest {

    @Test
    public void escapesSingleQuotes() {
        assertEquals("don\\'t", Messenger.escapeForJSStringLiteral("don't"));
    }

    @Test
    public void escapesBackslashes() {
        assertEquals("a\\\\b", Messenger.escapeForJSStringLiteral("a\\b"));
    }

    @Test
    public void escapesNewlinesAndTabs() {
        assertEquals("a\\nb\\rc\\td", Messenger.escapeForJSStringLiteral("a\nb\rc\td"));
    }

    @Test
    public void escapesLineSeparator() {
        assertEquals("a\\u2028b", Messenger.escapeForJSStringLiteral("a\u2028b"));
    }

    @Test
    public void escapesParagraphSeparator() {
        assertEquals("a\\u2029b", Messenger.escapeForJSStringLiteral("a\u2029b"));
    }

    @Test
    public void escapesControlCharacters() {
        assertEquals("\\u0001\\u001f", Messenger.escapeForJSStringLiteral("\u0001\u001f"));
    }

    @Test
    public void neutralizesInjectionPayload() {
        final String malicious = "');alert('xss";
        assertEquals("\\');alert(\\'xss", Messenger.escapeForJSStringLiteral(malicious));
    }

    @Test
    public void leavesSafeCharactersUnchanged() {
        final String safe = "abcXYZ123_-.~ ";
        assertEquals(safe, Messenger.escapeForJSStringLiteral(safe));
    }

    @Test
    public void emptyStringStaysEmpty() {
        assertEquals("", Messenger.escapeForJSStringLiteral(""));
    }
}
