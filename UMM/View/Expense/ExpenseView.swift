//
//  ExpenseView.swift
//  UMM
//
//  Created by 김태현 on 10/11/23.
//

import SwiftUI

struct ExpenseView: View {
    @State var selectedTab = 0
    @Namespace var namespace
    @ObservedObject var expenseViewModel = ExpenseViewModel()
    let exchangeRateHandler = ExchangeRateHandler.shared
    @EnvironmentObject var mainVM: MainViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                
//                settingViewButton
                
                travelChoiceView
                
                todayExpenseHeader
                
                tabViewButton
                
                Spacer()
                
                TabView(selection: $selectedTab) {
                    TodayExpenseView(expenseViewModel: expenseViewModel, selectedTab: $selectedTab, namespace: namespace)
                        .tag(0)
                        .contentShape(Rectangle())
                        .gesture(DragGesture().onChanged({_ in}))
                        .simultaneousGesture(TapGesture())
                    AllExpenseView(expenseViewModel: expenseViewModel, selectedTab: $selectedTab, namespace: namespace)
                        .tag(1)
                        .contentShape(Rectangle())
                        .gesture(DragGesture().onChanged({_ in}))
                        .simultaneousGesture(TapGesture())
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.horizontal, 20)
            .ignoresSafeArea()
            .onAppear {
                expenseViewModel.fetchExpense()
                expenseViewModel.fetchTravel()
            }
            .sheet(isPresented: $expenseViewModel.travelChoiceHalfModalIsShown) {
                TravelChoiceInExpenseModal(selectedTravel: $mainVM.selectedTravel, selectedCountry: $expenseViewModel.selectedCountry)
                    .presentationDetents([.height(289 - 34)])
            }
            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    travelChoiceView
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    NavigationLink(destination: SettingView()) {
//                        Image(systemName: "gearshape.fill")
//                            .font(.system(size: 20))
//                            .foregroundStyle(Color.gray300)
//                    }
//                }
            }
        }
    }
    
    private var settingViewButton: some View {
        NavigationLink {
            SettingView()
        } label: {
            HStack {
                Spacer()
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.gray300)
            }
            .ignoresSafeArea(.all)
            .padding(.leading, 3)
            .padding(.top, 3)
        }
    }
    
    private var todayExpenseHeader: some View {
        HStack(spacing: 0) {
            Text("가계부")
                .font(.display2)
            Spacer()
        }
        .padding(.top, 10)
    }
    
    private var travelChoiceView: some View {
        HStack(alignment: .center, spacing: 0) {
            Spacer()
            Button {
                expenseViewModel.travelChoiceHalfModalIsShown = true
            } label: {
                ZStack {
                    Capsule()
                        .foregroundStyle(.white)
                        .layoutPriority(-1)
                    
                    Capsule()
                        .strokeBorder(.mainPink, lineWidth: 1.0)
                        .layoutPriority(-1)
                    
                    HStack(spacing: 12) {
                        Text(mainVM.selectedTravel?.name != "Default" ? mainVM.selectedTravel?.name ?? "-" : "-")
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
            Spacer()
        }
        .padding(.top, 80)
    }
    
        private var tabViewButton: some View {
            HStack(spacing: 0) {
                ForEach((TabbedItems.allCases), id: \.self) { item in
                    ExpenseTabBarItem(selectedTab: $selectedTab, namespace: namespace, title: item.title, tab: item.rawValue)
                        .padding(.top, 8)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 0)
        }
}

struct ExpenseTabBarItem: View {
    @Binding var selectedTab: Int
    let namespace: Namespace.ID
    
    var title: String
    var tab: Int
    
    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 0) {
                Text(title)
                    .font(.subhead3_1)
                    .foregroundStyle(selectedTab == tab ? .black : .gray300)

                ZStack {
                    Divider()
                        .frame(height: 2)
                        .padding(.top, 11)
                    if selectedTab == tab {
                        Color.black
                            .matchedGeometryEffect(id: "underline", in: namespace.self)
                            .frame(height: 2)
                            .padding(.top, 11)
                            .padding(.horizontal)
                    } else {
                        Color.clear
                            .frame(height: 2)
                            .padding(.top, 11)
                            .padding(.horizontal)
                    }
                }
            }
            .animation(.spring(), value: selectedTab)
        }
        .buttonStyle(.plain)
    }
}

enum TabbedItems: Int, CaseIterable {
    case todayExpense
    case allExpense
    
    var title: String {
        switch self {
        case .todayExpense:
            return "일별 지출"
        case .allExpense:
            return "전체 지출"
        }
    }
}

// #Preview {
//    ExpenseView()
// }
