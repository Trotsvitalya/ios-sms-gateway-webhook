import SwiftUI

struct RuleEditView: View {
    @Environment(\.presentationMode) var presentationMode
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
                Section(header: Text("Відправник")) {
                    TextField("Номер або * для всіх", text: $sender)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Toggle("Регулярний вираз (RegEx)", isOn: $isSenderRegex)
                }

                Section(header: Text("Фільтр тексту SMS (необов'язково)")) {
                    TextField("Фільтр підрядка в SMS", text: $smsFilter)
                }

                Section(header: Text("Webhook URL")) {
                    TextField("https://...", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("JSON Шаблон")) {
                    TextEditor(text: $template)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 120)
                    Text("Змінні: %from%, %text%, %sentStamp%, %receivedStamp%, %sim%")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("HTTP Заголовки (JSON)")) {
                    TextEditor(text: $headers)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 60)
                }

                Section {
                    Button(action: testRule) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Надіслати тестове SMS на цей URL")
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "Нове правило" : "Редагування правила")
            .navigationBarItems(
                leading: Button("Скасувати") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Зберегти") {
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
