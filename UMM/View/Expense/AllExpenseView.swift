//
//  AllExpenseView.swift
//  UMM
//
//  Created by 김태현 on 10/11/23.
//

import SwiftUI

struct AllExpenseView: View {
    @ObservedObject var expenseViewModel: ExpenseViewModel
    @ObservedObject var dummyRecordViewModel: DummyRecordViewModel

    @State private var selectedTravel: Travel?

    init() {
        self.expenseViewModel = ExpenseViewModel()
        self.dummyRecordViewModel = DummyRecordViewModel()
    }

    var body: some View {
        ScrollView {
            Text("전체 지출")
            
            // Picker: 여행별
            Picker("현재 여행", selection: $selectedTravel) {
                ForEach(dummyRecordViewModel.savedTravels, id: \.self) { travel in
                    Text(travel.name ?? "no name").tag(travel as Travel?) // travel의 id가 선택지로
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedTravel) { newValue in
                print(newValue?.name ?? "")
            }
                        
            Button {
                expenseViewModel.addExpense(travel: selectedTravel ?? Travel(context: dummyRecordViewModel.viewContext))
                findCurrentTravel()
            } label: {
                Text("지출 추가")
            }
            
            Spacer()
            
            // 여행별 + 날짜별 리스트
            // 국가별로 나눠서 보여줌
            let filteredExpensesByTravel = expenseViewModel.filterExpensesByTravel(selectedTravelID: selectedTravel?.id ?? UUID())
            drawExpensesByCategory(expenses: filteredExpensesByTravel)

        }
        .onAppear {
            print("####")
            print("TodayExpenseView Appeared")
            expenseViewModel.fetchExpense()
            dummyRecordViewModel.fetchDummyTravel()
            self.selectedTravel = findCurrentTravel()
        }
    }
}

// 항목별로 비용 항목을 분류하여 표시
private func drawExpensesByCategory(expenses: [Expense]) -> some View {
    let groupedExpenses = Dictionary(grouping: expenses, by: { $0.category })
    
    return ForEach(groupedExpenses.sorted(by: { $0.key < $1.key }), id: \.key) { category, expenses in
        Section(header: Text("\(category)")) {
            ForEach(expenses, id: \.id) { expense in
                if let payDate = expense.payDate {
                    VStack {
                        HStack {
                            Text(expense.info ?? "no info")
                            Text("\(expense.category)")
                        }
                        Text(payDate.description)
                    }
                    .padding()
                }
            }
            Divider()
        }
    }
}

#Preview {
    AllExpenseView()
}
