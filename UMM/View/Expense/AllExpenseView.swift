//
//  AllExpenseView.swift
//  UMM
//
//  Created by 김태현 on 10/11/23.
//

import SwiftUI
import Charts

struct AllExpenseView: View {
    @ObservedObject var expenseViewModel: ExpenseViewModel
    @ObservedObject var dummyRecordViewModel: DummyRecordViewModel
    @State private var selectedPaymentMethod: Int64 = -2
    @Binding var selectedTab: Int
    let namespace: Namespace.ID
    
    init(selectedTab: Binding<Int>, namespace: Namespace.ID) {
        self.expenseViewModel = ExpenseViewModel()
        self.dummyRecordViewModel = DummyRecordViewModel()
        self._selectedTab = selectedTab
        self.namespace = namespace
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                travelChoiceView
                Spacer()
                settingView
            }
            allExpenseTitle
            tabViewButton
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    countryPicker
                    drawExpensesByCategory
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .onAppear {
            expenseViewModel.fetchExpense()
            dummyRecordViewModel.fetchDummyTravel()
//            expenseViewModel.selectedTravel = findCurrentTravel()
            
            expenseViewModel.filteredExpenses = getFilteredExpenses()
            expenseViewModel.groupedExpenses = Dictionary(grouping: expenseViewModel.filteredExpenses, by: { $0.category })
        }
        .sheet(isPresented: $expenseViewModel.travelChoiceHalfModalIsShown) {
            TravelChoiceModalBinding(selectedTravel: $expenseViewModel.selectedTravel)
                .presentationDetents([.height(289 - 34)])
        }
    }
    
    // MARK: - 뷰
    private var travelChoiceView: some View {
        Button {
            expenseViewModel.travelChoiceHalfModalIsShown = true
            print("expenseViewModel.travelChoiceHalfModalIsShown = true")
        } label: {
            ZStack {
                Capsule()
                    .foregroundStyle(.white)
                    .layoutPriority(-1)
                
                Capsule()
                    .strokeBorder(.mainPink, lineWidth: 1.0)
                    .layoutPriority(-1)
                
                HStack(spacing: 12) {
                    Text(expenseViewModel.selectedTravel?.name != "Default" ? expenseViewModel.selectedTravel?.name ?? "-": "-")
                        .font(.subhead2_2)
                        .foregroundStyle(.black)
                    Image("recordTravelChoiceDownChevron")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                .padding(.vertical, 6)
                .padding(.leading, 16)
                .padding(.trailing, 12)
            }
        }
        .padding(.top, 80)
    }
    
    private var travelPicker: some View {
        Picker("현재 여행", selection: $expenseViewModel.selectedTravel) {
            ForEach(dummyRecordViewModel.savedTravels, id: \.self) { travel in
                Text(travel.name ?? "no name").tag(travel as Travel?) // travel의 id가 선택지로
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onReceive(expenseViewModel.$selectedTravel) { _ in
            DispatchQueue.main.async {
                expenseViewModel.filteredExpenses = getFilteredExpenses()
                expenseViewModel.groupedExpenses = Dictionary(grouping: expenseViewModel.filteredExpenses, by: { $0.category })
                print("travelPicker | expenseViewModel.selectedCountry: \(expenseViewModel.selectedCountry)")
            }
        }
    }
    
    private var settingView: some View {
        Button(action: {}, label: {
            Image(systemName: "wifi")
                .font(.system(size: 16))
                .foregroundStyle(.gray300)
        })
    }
    
    private var allExpenseTitle: some View {
        HStack(spacing: 0) {
            Text("지출 관리")
                .font(.display2)
                .padding(.top, 12)
            Spacer()
        }
    }
    
    private var tabViewButton: some View {
        HStack(spacing: 0) {
            ForEach((TabbedItems.allCases), id: \.self) { item in
                ExpenseTabBarItem(selectedTab: $selectedTab, namespace: namespace, title: item.title, tab: item.rawValue)
                    .padding(.top, 8)
            }
        }
        .padding(.top, 32)
    }
    
    private var countryPicker: some View {
        let allExpensesInSelectedTravel = expenseViewModel.filteredExpenses
        let countries = [-2] + Array(Set(allExpensesInSelectedTravel.compactMap { $0.country })).sorted { $0 < $1 } // 중복 제거
        
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(countries, id: \.self) { country in
                    Button(action: {
                        DispatchQueue.main.async {
                            expenseViewModel.selectedCountry = Int64(country)
                            expenseViewModel.filteredExpenses = getFilteredExpenses()
                            expenseViewModel.groupedExpenses = Dictionary(grouping: expenseViewModel.filteredExpenses, by: { $0.category })
                            print("countryPicker | expenseViewModel.groupedExpenses: \(expenseViewModel.groupedExpenses.count)")
                            print("countryPicker | expenseViewModel.selectedCountry: \(expenseViewModel.selectedCountry)")
                            print("countryPicker | country: \(country)")
                        }
                    }, label: {
                        HStack(spacing: 0) {
                            Image(systemName: "wifi")
                                .font(.system(size: 16))
                            Text("\(Country.titleFor(rawValue: Int(country)))")
                                .padding(.leading, 4)
                        }
                        .font(.caption2)
                        .frame(width: 61) // 폰트 개수가 다르고, 크기는 고정되어 있어서 상수 값을 주었습니다.
                        .padding(.vertical, 7)
                        .background(expenseViewModel.selectedCountry == country ? Color.black: Color.white)
                        .foregroundColor(expenseViewModel.selectedCountry == country ? Color.white: Color.gray300)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray200, lineWidth: 2)
                        )
                    })
                }
            }
            .padding(.top, 16)
        }
    }
    
    private func getExpenseArray(for country: Int64) -> [Expense] {
        if country == expenseViewModel.selectedCountry {
            return expenseViewModel.filteredExpenses.filter { $0.country == country }
        } else {
            return expenseViewModel.filteredExpenses
        }
    }
    
    private var drawExpensesByCategory: some View {
        let countryArray = [Int64](Set<Int64>(expenseViewModel.groupedExpenses.keys)).sorted { $0 < $1 }

        // selectedCountry가 -2인 경우 전체 지출을 한 번만 그림
        if expenseViewModel.selectedCountry == -2 {
            let expenseArray = expenseViewModel.filteredExpenses
            return AnyView(drawExpenseContent(for: -2, with: expenseArray))
        } else {
            // selectedCountry가 특정 국가인 경우 해당 국가의 지출을 그림
            return AnyView(ForEach(countryArray, id: \.self) { country in
                VStack {
                    let expenseArray = getExpenseArray(for: country)
                    if country == expenseViewModel.selectedCountry {
                        drawExpenseContent(for: country, with: expenseArray)
                    }
                }
            })
        }
    }
    
    // 1. 나라별
    // 1-1. 항목별
    private func drawExpenseContent(for country: Int64, with expenses: [Expense]) -> some View {
        let categoryArray = [Int64]([-1, 0, 1, 2, 3, 4, 5])
        let totalSum = expenses.reduce(0) { $0 + $1.payAmount } // 모든 결제 수단 합계
        let indexedSumArrayInPayAmountOrder = getPayAmountOrderedIndicesOfCategory(categoryArray: categoryArray,
                                                                                   expenseArray: expenses)
        let currencies = Array(Set(expenses.map { $0.currency })).sorted { $0 < $1 }

        return VStack(alignment: .leading, spacing: 0) {
            
            // allExpenseSummary: 합계
            NavigationLink {
                AllExpenseDetailView(
                    selectedTravel: expenseViewModel.selectedTravel,
                    selectedCategory: -2,
                    selectedCountry: expenseViewModel.selectedCountry,
                    selectedPaymentMethod: -2
                )
            } label: {
                HStack(spacing: 0) {
                    Text("\(expenseViewModel.formatSum(from: totalSum, to: 0))원")
                        .font(.display4)
                        .foregroundStyle(.black)
                    Image(systemName: "wifi")
                        .font(.system(size: 24))
                        .foregroundStyle(.gray200)
                        .padding(.leading, 16)
                }
                .padding(.top, 32)
            }

            // allExpenseSummary: 화폐별
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(currencies.indices, id: \.self) { idx in
                        let currency = currencies[idx]
                        let sum = expenses.filter({ $0.currency == currency }).reduce(0) { $0 + $1.payAmount } // 결제 수단 별로 합계
                        
                        Text("\(currency): \(expenseViewModel.formatSum(from: sum, to: 2))")
                            .font(.caption2)
                            .foregroundStyle(.gray300)
                        if idx != currencies.count - 1 {
                            Circle()
                                .frame(width: 3, height: 3)
                                .foregroundStyle(.gray300)
                                .padding(.horizontal, 3)
                        }
                    }
                }
                .padding(.top, 10)
            }
            
            // allExpenseBarGraph
            BarGraph(data: indexedSumArrayInPayAmountOrder)
                .padding(.top, 22)
            
            Divider()
                .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<categoryArray.count, id: \.self) { index in
                    let categoryName = indexedSumArrayInPayAmountOrder[index].0
                    let categorySum = indexedSumArrayInPayAmountOrder[index].1
                    let totalSum = indexedSumArrayInPayAmountOrder.map { $0.1 }.reduce(0, +)
                    
                    NavigationLink {
                        AllExpenseDetailView(
                            selectedTravel: expenseViewModel.selectedTravel,
                            selectedCategory: indexedSumArrayInPayAmountOrder[index].0,
                            selectedCountry: expenseViewModel.selectedCountry,
                            selectedPaymentMethod: -2
                        )
                    } label: {
                        HStack(alignment: .center, spacing: 0) {
                            Image(systemName: "wifi")
                                .font(.system(size: 36))
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(ExpenseInfoCategory.descriptionFor(rawValue: Int(categoryName)))")
                                    .font(.subhead2_1)
                                    .foregroundStyle(.black)
                                HStack(alignment: .center, spacing: 0) {
                                    Text("\(expenseViewModel.formatSum(from: categorySum / totalSum * 100, to: 1))%")
                                        .font(.caption2)
                                        .foregroundStyle(.gray300)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.leading, 10)
                            
                            Spacer()
                            
                            HStack(alignment: .center, spacing: 0) {
                                Text("\(expenseViewModel.formatSum(from: categorySum, to: 0))원")
                                    .font(.subhead3_1)
                                    .foregroundStyle(.black)
                                    .padding(.leading, 3)
                                    .padding(.trailing, 12)
                                Image(systemName: "wifi")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.gray300)
                                    
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    // 최종 배열
    private func getFilteredExpenses() -> [Expense] {
        let filteredByTravel = expenseViewModel.filterExpensesByTravel(expenses: expenseViewModel.savedExpenses, selectedTravelID: expenseViewModel.selectedTravel?.id ?? UUID())
        
        return filteredByTravel
    }
}

private func getPayAmountOrderedIndicesOfCategory(categoryArray: [Int64], expenseArray: [Expense]) -> [(Int64, Double)] {
    let filteredExpenseArrayArray = categoryArray.map { category in
        expenseArray.filter {
            $0.category == category
        }
    }
    
    let sumArray = filteredExpenseArrayArray.map { expenseArray in
        expenseArray.reduce(0) {
            $0 + $1.payAmount
        }
    }
    let indexedSumArray: [(Int64, Double)] = [
        (categoryArray[0], sumArray[0]),
        (categoryArray[1], sumArray[1]),
        (categoryArray[2], sumArray[2]),
        (categoryArray[3], sumArray[3]),
        (categoryArray[4], sumArray[4]),
        (categoryArray[5], sumArray[5]),
        (categoryArray[6], sumArray[6])
    ].sorted {
        $0.1 >= $1.1
    }
    return indexedSumArray
}

struct CurrencyForChart: Identifiable, Hashable {
    let id = UUID()
    let currency: Int64
    let sum: Double

    init(currency: Int64, sum: Double) {
        self.currency = currency
        self.sum = sum
    }
}

struct ExpenseForChart: Identifiable, Hashable {
    let id = UUID()
    let name: Int64
    let value: Double

    init(_ tuple: (Int64, Double)) {
        self.name = tuple.0
        self.value = tuple.1
    }
}

struct BarGraph: View {
    var data: [(Int64, Double)]
    
    private var totalSum: Double {
        return data.map { $0.1 }.reduce(0, +)
    }
    
    var body: some View {
        let totalWidth = UIScreen.main.bounds.size.width - 40
        
        HStack(spacing: 0) {
            ForEach(data, id: \.0) { categoryRawValue, value in
                BarElement(
                    color: ExpenseInfoCategory(rawValue: Int(categoryRawValue))?.color ?? Color.gray,
                    width: (CGFloat(value / totalSum) * totalWidth),
                    isFirstElement: data.first?.0 == categoryRawValue,
                    isLastElement: data.last?.0 == categoryRawValue
                )
            }
        }
    }
}

struct BarElement: View {
    
    let color: Color
    let width: CGFloat
    let isFirstElement: Bool
    let isLastElement: Bool
    
   var body: some View {
       Rectangle()
           .fill(color)
           .frame(width: max(0, width), height: 24)
           .cornerRadius(isFirstElement ? 6 : 0, corners: [.topLeft, .bottomLeft])
           .cornerRadius(isLastElement ? 6 : 0, corners: [.topRight, .bottomRight])
           .padding(.trailing, 2)
   }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

//  #Preview {
//      AllExpenseView(selectedTab: .constant(1), namespace: Namespace.ID)
//  }
