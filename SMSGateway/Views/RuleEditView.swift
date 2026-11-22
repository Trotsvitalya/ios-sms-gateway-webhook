import SwiftUI

struct RuleEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var loc = LocalizationManager.shared
    @Binding var rule: ForwardingRule
    var isNew: Bool
    var onSave: (ForwardingRule) -> Void

    @State private var sender: String = ""
    @State private var isSenderRegex: Bool = false
    @State private var smsFilter: String = ""
    @State private var url: String = ""
    @State private var template: String = ""
    @State private var headers: String = ""
    @State private var isEnabled: Bool = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(loc.localized(.senderSection))) {
                    TextField(loc.localized(.senderPlaceholder), text: $sender)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Toggle(loc.localized(.regexToggle), isOn: $isSenderRegex)
                }

                Section(header: Text(loc.localized(.smsFilterSection))) {
                    TextField(loc.localized(.smsFilterPlaceholder), text: $smsFilter)
                }

                Section(header: Text(loc.localized(.webhookUrlSection))) {
                    TextField("https://...", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text(loc.localized(.jsonTemplateSection))) {
                    TextEditor(text: $template)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 120)
                    Text(loc.localized(.variablesHint))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(header: Text(loc.localized(.headersSection))) {
                    TextEditor(text: $headers)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 60)
                }

                Section {
                    Button(action: testRule) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text(loc.localized(.sendTestButton))
                        }
                    }
                }
            }
            .navigationTitle(isNew ? loc.localized(.ruleNewTitle) : loc.localized(.ruleEditTitle))
            .navigationBarItems(
                leading: Button(loc.localized(.cancel)) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(loc.localized(.save)) {
                    saveAndDismiss()
                }.disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .onAppear {
                self.sender = rule.sender
                self.isSenderRegex = rule.isSenderRegex
                self.smsFilter = rule.smsFilter
                self.url = rule.url
                self.template = rule.template
                self.headers = rule.headers
                self.isEnabled = rule.isEnabled
            }
        }
    }

    private func saveAndDismiss() {
        var updated = rule
        updated.sender = sender
        updated.isSenderRegex = isSenderRegex
        updated.smsFilter = smsFilter
        updated.url = url
        updated.template = template
        updated.headers = headers
        updated.isEnabled = isEnabled
        onSave(updated)
        presentationMode.wrappedValue.dismiss()
    }

    private func testRule() {
        let tempRule = ForwardingRule(
            id: rule.id,
            sender: sender,
            isSenderRegex: isSenderRegex,
            smsFilter: smsFilter,
            url: url,
            template: template,
            headers: headers,
            isEnabled: true
        )
        GatewayEngine.shared.sendTest(rule: tempRule)
    }
}
