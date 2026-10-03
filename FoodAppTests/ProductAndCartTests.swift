//
//  ProductAndCartTests.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import XCTest
@testable import FoodApp

@MainActor
final class ProductAndCartTests: XCTestCase {
    private let small = OptionChoice(id: 1, name: "Small", extraPrice: 0)
    private let large = OptionChoice(id: 3, name: "Large", extraPrice: 100)
    private let cheese = OptionChoice(id: 11, name: "Cheese", extraPrice: 30)

    private func makeItem(restaurantId: Int = 1) -> MenuItem {
        MenuItem(id: 1, restaurantId: restaurantId, name: "Pizza", description: "", price: 200,
                 isVeg: true, imageUrl: nil, variants: [small, large], addOns: [cheese])
    }

    func test_defaultSelection_isFirstVariant() {
        let vm = ProductDetailViewModel(item: makeItem())
        XCTAssertEqual(vm.selectedVariant, small)
        XCTAssertEqual(vm.totalPrice, 200)
    }

    func test_price_updatesWithVariantAddOnAndQuantity() {
        let vm = ProductDetailViewModel(item: makeItem())
        vm.selectedVariant = large
        vm.toggleAddOn(cheese)
        vm.increment()
        XCTAssertEqual(vm.totalPrice, 660)   // (200 + 100 + 30) * 2
    }

    func test_toggleAddOnTwice_removesIt() {
        let vm = ProductDetailViewModel(item: makeItem())
        vm.toggleAddOn(cheese); vm.toggleAddOn(cheese)
        XCTAssertTrue(vm.selectedOptions.filter { $0.id == 11 }.isEmpty)
    }

    func test_quantity_neverBelowOne() {
        let vm = ProductDetailViewModel(item: makeItem())
        vm.decrement()
        XCTAssertEqual(vm.quantity, 1)
    }

    func test_cart_sameItemSameOptions_mergesQuantity() {
        let cart = CartStore()
        let item = ProductDetailViewModel(item: makeItem()).makeCartItem()
        _ = cart.add(item); _ = cart.add(item)
        XCTAssertEqual(cart.items.count, 1)
        XCTAssertEqual(cart.items.first?.quantity, 2)
    }

    func test_cart_differentRestaurant_returnsConflict() {
        let cart = CartStore()
        _ = cart.add(ProductDetailViewModel(item: makeItem(restaurantId: 1)).makeCartItem())
        let result = cart.add(ProductDetailViewModel(item: makeItem(restaurantId: 2)).makeCartItem())
        XCTAssertEqual(result, .restaurantConflict)
        XCTAssertEqual(cart.items.count, 1)
    }

    func test_cart_couponApplied_andRemovedWhenQuantityZero() {
        let cart = CartStore()
        let item = ProductDetailViewModel(item: makeItem()).makeCartItem()
        _ = cart.add(item)
        cart.apply(Coupon.find("save20")!)
        XCTAssertNotNil(cart.coupon)
        cart.updateQuantity(id: cart.items[0].id, quantity: 0)
        XCTAssertTrue(cart.items.isEmpty)
        XCTAssertNil(cart.coupon)
    }
}
