//
//  ItemSearchFeatureTests.swift
//  EorzeaToolkitTests
//
//  Created by Kuan-Chung Chen on 2026/11/12.
//

import Testing
import ComposableArchitecture
@testable import EorzeaToolkit

@MainActor
struct ItemSearchFeatureTests {

    @Test func taskLoadsCatalogWithoutRemoteRefresh() async {
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = {
                catalog
            }
            
            $0.itemData.refresh = { version in
                #expect(version == catalog.version)
                return nil
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
        }
        
        await store.receive(\.refreshResponse, nil)
    }
    
    @Test func taskLoadsCatalogWithRemoteRefresh() async {
        let refreshVersion = "v2"
        let catalog = ItemSearchFixture.catalog()
        let refreshCatalog = ItemSearchFixture.catalog(version: refreshVersion)
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = {
                catalog
            }
            
            $0.itemData.refresh = { _ in
                refreshCatalog
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
        }
        
        await store.receive(\.refreshResponse) {
            $0.catalog = refreshCatalog
        }
    }
    
    @Test func remoteRefreshFailureKeepsTheCatalog() async {
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = {
                catalog
            }
            
            $0.itemData.refresh = { version in
                throw FetchError()
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
        }
        
        await store.receive(\.refreshResponse, nil)
    }

    @Test func taskFailureShowsError() async {
        let store = TestStore(initialState: ItemSearchFeature.State()) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = {
                throw FetchError()
            }
        }
        
        await store.send(.task) {
            $0.loadState = .loading
        }
        
        await store.receive(\.catalogResponse.failure) {
            $0.loadState = .failed("fetch failed")
        }
    }
    
    @Test(arguments: [ItemSearchFeature.LoadState.loading, .loaded])
    func taskDoesNothingWhenLoadingOrLoaded(loadState: ItemSearchFeature.LoadState) async {
        let store = TestStore(initialState: ItemSearchFeature.State(loadState: loadState)) {
            ItemSearchFeature()
        }
        
        await store.send(.task)
    }
    
    @Test func taskRetriesAfterFailure() async {
        let catalog = ItemSearchFixture.catalog()
        let store = TestStore(initialState: ItemSearchFeature.State(loadState: .failed("x"))) {
            ItemSearchFeature()
        } withDependencies: {
            $0.itemData.load = { catalog }
            $0.itemData.refresh = { _ in nil }
        }

        await store.send(.task) { $0.loadState = .loading }
        await store.receive(\.catalogResponse.success) {
            $0.loadState = .loaded
            $0.catalog = catalog
        }
        await store.receive(\.refreshResponse)
    }
}
