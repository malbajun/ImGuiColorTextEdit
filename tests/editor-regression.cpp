#include "TextEditor.h"
#include "TextDiff.h"
#include <iostream>
#include <stdexcept>

static void check(bool condition, const char* message) {
    if (!condition) { throw std::runtime_error(message); }
}

static void frame(TextEditor& editor) {
    ImGui::NewFrame();
    ImGui::SetNextWindowSize(ImVec2(800, 600));
    ImGui::Begin("regression");
    editor.Render("editor", ImVec2(700, 450));
    ImGui::End();
    ImGui::Render();
}

static float whitespaceSpan(ImU32 color) {
    float left = std::numeric_limits<float>::max();
    float right = std::numeric_limits<float>::lowest();
    const auto* data = ImGui::GetDrawData();
    for (int i = 0; i < data->CmdListsCount; ++i) {
        for (const auto& vertex : data->CmdLists[i]->VtxBuffer) {
            if (vertex.col == color) {
                left = std::min(left, vertex.pos.x);
                right = std::max(right, vertex.pos.x);
            }
        }
    }
    check(right >= left, "tab arrow rendered");
    return right - left;
}

int main() {
    try {
        ImGui::CreateContext();
        auto& io = ImGui::GetIO();
        io.IniFilename = nullptr;
        io.DisplaySize = ImVec2(1024, 768);
        io.DeltaTime = 1.0f / 60.0f;
        unsigned char* pixels;
        int width, height;
        io.Fonts->GetTexDataAsRGBA32(&pixels, &width, &height);
        TextEditor editor;
        editor.SetInsertSpacesOnTabs(false);
        editor.SetText("one\n\tUnicode: \xD0\x90");
        check(editor.GetLineCount() == 2, "UTF-8 line count");
        check(editor.GetText() == "one\n\tUnicode: \xD0\x90\n", "UTF-8 roundtrip");
        editor.SetText(std::u16string_view(u"wide\ntext"));
        check(editor.GetTextAsU16String() == u"wide\ntext\n", "UTF-16 roundtrip");
        check(TextEditor::LookupLanguage("Lua") != nullptr, "installed language registry");
        editor.SetLanguage(TextEditor::LookupLanguage("Lua"));
        frame(editor);

        editor.SetText("\tvalue");
        editor.SetShowTabsEnabled(true);
        check(editor.IsShortTabsEnabled(), "upstream short-tab default");
        editor.SetShortTabsEnabled(false);
        auto colors = TextEditor::GetDarkPalette();
        const ImU32 whitespaceColor = IM_COL32(1, 2, 3, 255);
        colors[static_cast<size_t>(TextEditor::Color::whitespace)] = whitespaceColor;
        editor.SetPalette(colors);
        frame(editor);
        const auto longSpan = whitespaceSpan(whitespaceColor);
        const auto textColumn = editor.DocPos2ScreenPos(TextEditor::DocPos(0, 1)).x;
        editor.SetShortTabsEnabled(true);
        frame(editor);
        check(whitespaceSpan(whitespaceColor) < longSpan, "short arrow has smaller rendered span");
        check(editor.DocPos2ScreenPos(TextEditor::DocPos(0, 1)).x == textColumn, "tab layout unaffected");
        check(editor.GetLineText(0) == "\tvalue", "tab text unaffected");

        int transactions = 0;
        int changes = 0;
        editor.SetTransactionCallback([&](const std::vector<TextEditor::Change>& edits) {
            check(!edits.empty(), "transaction contains changes");
            ++transactions;
        });
        editor.SetChangeCallback([&]() { ++changes; });
        editor.SetText("hello");
        editor.SetText(std::u16string_view(u"hello"));
        check(transactions == 0 && changes == 0, "SetText does not invoke callbacks directly");
        frame(editor);
        check(transactions == 0, "SetText resets without a transaction");
        editor.SetCursor(TextEditor::DocPos(0, 5));
        frame(editor);
        const auto changesBeforeInsert = changes;
        editor.ReplaceTextInAllCursors(" world");
        check(editor.GetText() == "hello world\n" && transactions == 1, "native insertion transaction");
        frame(editor);
        check(changes == changesBeforeInsert + 1, "native change callback");
        editor.Undo();
        check(editor.GetText() == "hello\n" && transactions == 2, "native undo callback");
        editor.Redo();
        check(editor.GetText() == "hello world\n" && transactions == 3, "native redo callback");
        editor.SetReadOnlyEnabled(true);
        editor.ReplaceTextInAllCursors("ignored");
        check(editor.GetText() == "hello world\n" && transactions == 3, "read-only insertion");
        editor.SetReadOnlyEnabled(false);
        editor.ClearTransactionCallback();
        editor.ClearChangeCallback();
        editor.SetText("object.member = value");
        auto isContext = [](ImWchar c) {
            return c != ' ' && c != '\t' && c != ',' && c != '(' && c != ')' && c != '=';
        };
        check(editor.GetContext(TextEditor::DocPos(0, 3), isContext) == "object.member", "native member context");
        editor.SetFindCloseButtonLabel("close");
        editor.OpenFindReplaceWindow();
        frame(editor);
        editor.CloseFindReplaceWindow();

        TextDiff diff;
        check(diff.IsShortTabsEnabled(), "diff short-tab default");
        diff.SetShortTabsEnabled(false);
        check(!diff.IsShortTabsEnabled(), "diff long-tab option");
        ImGui::DestroyContext();
        std::cout << "editor regression checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
