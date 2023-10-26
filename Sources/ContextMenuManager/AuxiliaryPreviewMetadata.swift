//
//  AuxiliaryPreviewMetadata.swift
//  
//
//  Created by Dominic Go on 10/27/23.
//

import Foundation


public struct AuxiliaryPreviewMetadata {
  
  // MARK: - Static Members
  // ----------------------

  /// amount to add to width - fix for layout bug
  ///
  /// if you use the actual width, it triggers a bug w/ autolayout where the
  /// aux. preview snaps to the top of the screen...
  ///
  static let auxiliaryViewExtraWidth = 0.5;
  
    // MARK: - Properties
  // --------------------
  
  /// whether to attach the `auxiliaryView` on the top or bottom of the
  /// context menu
  var auxPreviewPosition: ContextMenuMetadata.Position;
  
  var auxiliaryPreviewViewHeight: CGFloat?;
  var auxiliaryPreviewViewWidth: CGFloat?;
  
  var menuOffset: CGFloat;
  
  // MARK: - Properties - Computed
  // -----------------------------
  
  var auxiliaryPreviewViewWidthAdjusted: CGFloat? {
    guard let auxiliaryPreviewViewWidth = auxiliaryPreviewViewWidth
    else { return nil };
    
    return auxiliaryPreviewViewWidth + Self.auxiliaryViewExtraWidth;
  };
  
  // MARK: - Init
  // ------------
  
  public init?(
    contextMenuMetadata: ContextMenuMetadata,
    contextMenuManager: ContextMenuManager,
    auxiliaryPreviewConfig: AuxiliaryPreviewConfig,
    auxiliaryPreviewManager: ContextMenuAuxiliaryPreviewManager
  ) {
    
    let auxPreviewPosition: ContextMenuMetadata.Position = {
      switch auxiliaryPreviewConfig.anchorPosition {
        case .top   : return .top;
        case .bottom: return .bottom;
          
        case .automatic: break;
      };
      
      guard let menuPosition = contextMenuMetadata.menuPosition else {
        // the context menu does not have menu items, determine anchor position
        // of auxiliary view via the position of the preview in the screen
        return contextMenuMetadata.menuPreviewPosition == .bottom
          ? .top
          : .bottom;
      };
      
      return menuPosition
    }();
    
    self.auxPreviewPosition = auxPreviewPosition;
    
    let auxiliaryPreviewViewWidth: CGFloat? = {
      let computedWidth = auxiliaryPreviewConfig.auxiliaryPreviewPreferredWidth?.compute(
        computingForSizeKey: \.width,
        usingAuxiliaryPreviewManager: auxiliaryPreviewManager
      );
      
      let fallbackWidth =
        contextMenuManager.menuAuxiliaryPreviewView?.frame.width;
      
      return computedWidth ?? fallbackWidth;
    }();
    
    self.auxiliaryPreviewViewWidth = auxiliaryPreviewViewWidth;
    
    let auxiliaryPreviewViewHeight: CGFloat? = {
      let computedHeight: CGFloat? = auxiliaryPreviewConfig.auxiliaryPreviewPreferredWidth?.compute(
        computingForSizeKey: \.height,
        usingAuxiliaryPreviewManager: auxiliaryPreviewManager
      );
      
      let fallbackHeight =
        contextMenuManager.menuAuxiliaryPreviewView?.frame.height;
        
      return computedHeight ?? fallbackHeight;
    }();
    
    self.auxiliaryPreviewViewHeight = auxiliaryPreviewViewHeight;
    
    self.menuOffset = {
      guard let window = auxiliaryPreviewManager.window,
            let auxiliaryPreviewViewHeight = auxiliaryPreviewViewHeight
      else { return 0 };
      
      let safeAreaInsets = window.safeAreaInsets;
      
      let previewFrame = contextMenuMetadata.menuPreviewFrame;
      let windowHeight = window.bounds.height;
      
      let marginBase =
          auxiliaryPreviewConfig.auxiliaryPreviewMarginInner
        + auxiliaryPreviewConfig.auxiliaryPreviewMarginOuter;
      
      switch contextMenuMetadata.menuPreviewPosition {
        case .top:
          let topInsets = safeAreaInsets.top;
          let margin = marginBase + topInsets;
          
          let minEdgeY = auxiliaryPreviewViewHeight + topInsets + margin;
          let distanceToEdge = auxiliaryPreviewViewHeight - previewFrame.minY;
        
          return (previewFrame.minY <= minEdgeY)
            ? max((distanceToEdge + margin), 0)
            : 0;
          
        case .bottom:
          let margin = marginBase + safeAreaInsets.bottom;
          
          let tolerance = auxiliaryPreviewViewHeight + margin;
          let maxEdgeY = windowHeight - tolerance;
          
          let previewFrameMaxY =
              previewFrame.maxY
            + auxiliaryPreviewConfig.auxiliaryPreviewMarginInner;
          
          let distanceToEdge = windowHeight - previewFrame.maxY;
          
          return (previewFrameMaxY > maxEdgeY)
            ? -(auxiliaryPreviewViewHeight - distanceToEdge + margin)
            : 0;
      };
    }();
  };
};