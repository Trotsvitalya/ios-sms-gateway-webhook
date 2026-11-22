import SwiftUI

struct ContentView: View {
    @StateObject private var engine = GatewayEngine.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedTab = 0
    @State private var showingAddRule = false
    @State private var editingRule: ForwardingRule?

    var body: some View {
        TabView(selection: $selectedTab) {
            rulesTabView
                .tabItem {
                    Label(loc.localized(.tabRules), systemImage: "arrow.triangle.branch")
                }
                .tag(0)

            logsTabView
                .tabItem {
                    Label(loc.localized(.tabLogs), systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            settingsTabView
                .tabItem {
                    Label(loc.localized(.tabInfo), systemImage: "info.circle")
                }
                .tag(2)
        }
        .onAppear {
            engine.checkDatabaseStatus()
        }
    }

    // MARK: - Rules Tab
    private var rulesTabView: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(engine.isRunning ? loc.localized(.serviceActive) : loc.localized(.serviceStopped))
                                .font(.headline)
                                .foregroundColor(engine.isRunning ? .green : .secondary)
                            Text(engine.isRunning ? loc.localized(.serviceRunningSubtitle) : loc.localized(.serviceTapToStart))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { engine.isRunning },
                            set: { newValue in
                                if newValue {
                                    engine.start()
                                } else {
                                    engine.stop()
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }

                if !engine.isDbAvailable {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.localized(.dbUnavailableTitle))
                                    .font(.subheadline).bold()
                                Text(loc.localized(.dbUnavailableMessage))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section(header: HStack {
                    Text(loc.localized(.forwardingRulesHeader))
                    Spacer()
                    Button(action: { showingAddRule = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }) {
                    if engine.rules.isEmpty {
                        Text(loc.localized(.noRules))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(engine.rules.indices, id: \.self) { index in
                            let rule = engine.rules[index]
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(rule.sender.isEmpty ? "*" : rule.sender)
                                            .font(.headline)
                                        if rule.isSenderRegex {
                                            Text("RegEx")
                                                .font(.caption2)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                    Text(rule.url)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { engine.rules[index].isEnabled },
                                    set: { val in
                                        engine.rules[index].isEnabled = val
                                        engine.saveRules()
                                    }
                                ))
                                .labelsHidden()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingRule = engine.rules[index]
                            }
                        }
                        .onDelete(perform: deleteRule)
                    }
                }
            }
            .navigationTitle("SMS Gateway")
            .sheet(isPresented: $showingAddRule) {
                RuleEditView(
                    rule: .constant(ForwardingRule()),
                    isNew: true,
                    onSave: { newRule in
                        engine.rules.append(newRule)
                        engine.saveRules()
                    }
                )
            }
            .sheet(item: $editingRule) { rule in
                RuleEditView(
                    rule: .constant(rule),
                    isNew: false,
                    onSave: { updated in
                        if let idx = engine.rules.firstIndex(where: { $0.id == updated.id }) {
                            engine.rules[idx] = updated
                            engine.saveRules()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Logs Tab
    private var logsTabView: some View {
        NavigationView {
            List {
                if engine.logs.isEmpty {
                    Text(loc.localized(.logsEmpty))
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(engine.logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.sender).bold()
                                Spacer()
                                Text(log.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(log.message)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(3)

                            HStack {
                                Text(log.targetUrl)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                Text(log.status)
                                    .font(.caption2).bold()
                                    .foregroundColor(log.isSuccess ? .green : .red)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle(loc.localized(.logsTitle))
            .navigationBarItems(trailing: Button(loc.localized(.clearLogs)) {
                engine.clearLogs()
            }.disabled(engine.logs.isEmpty))
        }
    }

    // MARK: - Info Tab
    private var settingsTabView: some View {
        NavigationView {
            List {
                Section(header: Text(loc.localized(.languageHeader))) {
                    Picker(loc.localized(.languageHeader), selection: $loc.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text(loc.localized(.infoAboutHeader))) {
                    HStack {
                        Text(loc.localized(.appNameLabel))
                        Spacer()
                        Text(loc.localized(.appNameValue))
                    }
                    HStack {
                        Text(loc.localized(.compatLabel))
                        Spacer()
                        Text(loc.localized(.compatValue))
                    }
                    HStack {
                        Text(loc.localized(.dbStatusLabel))
                        Spacer()
                        Text(engine.isDbAvailable ? loc.localized(.dbConnected) : loc.localized(.dbDisconnected))
                            .foregroundColor(engine.isDbAvailable ? .green : .red)
                    }
                }

                Section(header: Text(loc.localized(.howItWorksHeader))) {
                    Text(loc.localized(.howItWorksDescription))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(loc.localized(.tabInfo))
        }
    }

    private func deleteRule(at offsets: IndexSet) {
        engine.rules.remove(atOffsets: offsets)
        engine.saveRules()
    }
}
