//
//  TodayExpenseView.swift
//  UMM
//
//  Created by 김태현 on 10/11/23.
//

import SwiftUI

struct TodayExpenseView: View {
    @ObservedObject var expenseViewModel: ExpenseViewModel
    @ObservedObject var dummyRecordViewModel: DummyRecordViewModel
    
    init() {
        self.expenseViewModel = ExpenseViewModel()
        self.dummyRecordViewModel = DummyRecordViewModel()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("일별 지출")
                
                // Picker: 여행별
                Picker("현재 여행", selection: $expenseViewModel.selectedTravel) {
                    ForEach(dummyRecordViewModel.savedTravels, id: \.self) { travel in
                        Text(travel.name ?? "no name").tag(travel as Travel?) // travel의 id가 선택지로
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onReceive(expenseViewModel.$selectedTravel) { _ in
                    DispatchQueue.main.async {
                        expenseViewModel.filteredExpenses = getFilteredExpenses()
                        expenseViewModel.groupedExpenses = Dictionary(grouping: expenseViewModel.filteredExpenses, by: { $0.country })
                        print("TodayExpenseView | onReceive | done")
                    }
                }
                
                // Picker: 날짜별
                DatePicker("날짜", selection: $expenseViewModel.selectedDate, displayedComponents: [.date])
                    .onReceive(expenseViewModel.$selectedDate) { _ in
                        DispatchQueue.main.async {
                            expenseViewModel.filteredExpenses = getFilteredExpenses()
                            expenseViewModel.groupedExpenses = Dictionary(grouping: expenseViewModel.filteredExpenses, by: { $0.country })
                        }
                    }
                
                Button {
                    expenseViewModel.addExpense(travel: expenseViewModel.selectedTravel ?? Travel(context: dummyRecordViewModel.viewContext))
                    DispatchQueue.main.async {
                        expenseViewModel.filteredExpenses = getFilteredExpenses()
                        expenseViewModel.groupedExpenses = Dictionary(grouping: expenseViewModel.filteredExpenses, by: { $0.country })
                    }
                } label: {
                    Text("지출 추가")
                }
                
                Spacer()
                
                drawExpensesByCountry
            }
        }
        .onAppear {
            print("TodayExpenseView Appeared")
            expenseViewModel.fetchExpense()
            dummyRecordViewModel.fetchDummyTravel()
            expenseViewModel.selectedTravel = findCurrentTravel()
            
            expenseViewModel.filteredExpenses = getFilteredExpenses()
            expenseViewModel.groupedExpenses = Dictionary(grouping: expenseViewModel.filteredExpenses, by: { $0.country })
        }
    }
    
    // 국가별 + 결제수단별 지출액 표시
    private var drawExpensesByCountry: some View {
        let countryArray = [Int64](Set<Int64>(expenseViewModel.groupedExpenses.keys)).sorted { $0 < $1 }
        
        return ForEach(countryArray, id: \.self) { country in
            VStack {
                let paymentMethodArray = Array(Set((expenseViewModel.groupedExpenses[country] ?? []).map { $0.paymentMethod })).sorted { $0 < $1 }
                let expenseArray = expenseViewModel.groupedExpenses[country] ?? []
                let totalSum = expenseArray.reduce(0) { $0 + $1.payAmount }
                
                let allCurrencySums = calculateCurrencySums(from: expenseArray)

                Text("나라: \(country)").font(.title3)
                
                NavigationLink {
                    TodayExpenseDetailView(
                        selectedTravel: expenseViewModel.selectedTravel,
                        selectedDate: expenseViewModel.selectedDate,
                        selectedCountry: country,
                        selectedPaymentMethod: -2, // paymentMethod와 상관 없이 모든 expense를 보여주기 위해 임의 값을 설정
                        currencySums: allCurrencySums
                    )
                } label: {
                    VStack {
                        Text("결제 수단: all")
                        Text("금액 합: \(totalSum)")
                    }
                }
                
                let currencies = Array(Set(expenseArray.map { $0.currency })).sorted { $0 < $1 }
                ForEach(currencies, id:\.self) { currency in
                    let sum = expenseArray.filter({ $0.currency == currency }).reduce(0) { $0 + $1.payAmount }
                    Text("\(currency): \(sum)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                }
                
                // 결제 수단 별 합계
                ForEach(paymentMethodArray, id: \.self) { paymentMethod in
                    VStack {
                        let filteredExpenseArray = expenseArray.filter { $0.paymentMethod == paymentMethod }
                        let sumPaymentMethod = filteredExpenseArray.reduce(0) { $0 + $1.payAmount }
                        
                        let allCurrencySums = calculateCurrencySums(from: filteredExpenseArray)

                        NavigationLink {
                            TodayExpenseDetailView(
                                selectedTravel: expenseViewModel.selectedTravel,
                                selectedDate: expenseViewModel.selectedDate,
                                selectedCountry: country,
                                selectedPaymentMethod: paymentMethod,
                                currencySums: allCurrencySums
                            )
                        } label:{
                            VStack{
                                Text("결제 수단 : \(paymentMethod)")
                                    .font(.headline)
                                    .padding(.bottom, 5)
                                Text("금액 합 : \(sumPaymentMethod)")
                            }
                        }
                        ForEach(currencies, id:\.self) { currency in
                            let sum = filteredExpenseArray.filter({ $0.currency == currency }).reduce(0) { $0 + $1.payAmount }
                            Text("\(currency): \(sum)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.bottom, 2)
                        }
                        
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func calculateCurrencySums(from expenses: [Expense]) -> [CurrencySum] {
        var currencySums = [CurrencySum]()
        let currencies = Array(Set(expenses.map { $0.currency })).sorted { $0 < $1 }

        for currency in currencies {
            let sum = expenses.filter({ $0.currency == currency }).reduce(0) { $0 + $1.payAmount }
            currencySums.append(CurrencySum(currency: currency, sum: sum))
        }
        
        return currencySums
    }

    private func getFilteredExpenses() -> [Expense] {
        let filteredByTravel = expenseViewModel.filterExpensesByTravel(expenses: expenseViewModel.savedExpenses, selectedTravelID: expenseViewModel.selectedTravel?.id ?? UUID())
        print("Filtered by travel: \(filteredByTravel.count)")
        
        let filteredByDate = expenseViewModel.filterExpensesByDate(expenses: filteredByTravel, selectedDate: expenseViewModel.selectedDate)
        print("Filtered by date: \(filteredByDate.count)")
        
        return filteredByDate
    }
    
}

struct CurrencySum {
    let currency: Int64
    let sum: Double
}


#Preview {
    TodayExpenseView()
}
