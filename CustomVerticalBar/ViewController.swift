//
//  ViewController.swift
//  CustomVerticalBar
//
//  Created by pradeepMac on 23/09/26.
//

import UIKit
import Combine

final class ViewController: UIViewController {

    private let lbl = UILabel()
    private let barView = UIView()
    private var barLeadingConstraint: NSLayoutConstraint!
    
    private var verticalConstraints: [NSLayoutConstraint] = []
    private var bottomConstraints: [NSLayoutConstraint] = []
    private var didApplyInitialLayout = false
    private var selectedItemIndex = 0

    private let items: [BarItem] = [
        BarItem(title: "Abdominals", iconName: "figure.core.training"),
        BarItem(title: "Chest", iconName: "figure.strengthtraining.traditional"),
        BarItem(title: "Waist", iconName: "figure.cross.training"),
        BarItem(title: "Presets", iconName: "slider.horizontal.3"),
        BarItem(title: "Hips", iconName: "figure.walk"),
        BarItem(title: "Back", iconName: "figure.cooldown"),
        BarItem(title: "Shoulders", iconName: "figure.arms.open"),
        BarItem(title: "Arms", iconName: "figure.strengthtraining.functional"),
        BarItem(title: "Legs", iconName: "figure.run"),
        BarItem(title: "Glutes", iconName: "figure.seated.side"),
        BarItem(title: "Full Body", iconName: "figure.mixed.cardio"),
        BarItem(title: "Favorites", iconName: "star.fill")
    ]

    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 76, height: 62)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.alwaysBounceHorizontal = false
        cv.alwaysBounceVertical = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(BarItemCell.self, forCellWithReuseIdentifier: BarItemCell.reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        configureHingeUpdates()
        HingeTabBarManager.shared.startMonitoring(on: view)
        
        // Listen to UIWindowScene geometry/coordinate space updates
        NotificationCenter.default.publisher(for: UIWindowScene.didActivateNotification)
            .compactMap { $0.object as? UIWindowScene }
            .sink { [weak self] scene in
                HingeTabBarManager.shared.evaluatePosition(in: scene, on: self!.view)
            }
            .store(in: &HingeTabBarManager.shared.cancellables)

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The collection view can be asked to lay out before the bar's final
        // orientation constraints are active. Re-apply once after UIKit has
        // resolved the actual bounds so the flow layout gets valid dimensions.
        if !didApplyInitialLayout {
            didApplyInitialLayout = true
            refreshBarPosition(animated: false)
        }
        if let scene = view.window?.windowScene {
            HingeTabBarManager.shared.evaluatePosition(in: scene, on: view)
        }
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        configureHingeUpdates()
        HingeTabBarManager.shared.startMonitoring(on: view)
        lbl.text = HingeTabBarManager.shared.displayText
        refreshBarPosition(animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        HingeTabBarManager.shared.stopMonitoring()
    }

    // MARK: - Hinge Updates
    private func configureHingeUpdates() {
        HingeTabBarManager.shared.onUpdate = { [weak self] in
            guard let self else { return }

            self.lbl.text = HingeTabBarManager.shared.displayText
            self.refreshBarPosition()
        }
    }

    // MARK: - Rotation

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: any UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            HingeTabBarManager.shared.refresh(from: self.view)
            self.refreshBarPosition()
            if let scene = view.window?.windowScene {
                HingeTabBarManager.shared.evaluatePosition(in: scene, on: view)
            }
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 18, weight: .semibold)
        lbl.numberOfLines = 0
        lbl.textColor = .label

        barView.backgroundColor = .secondarySystemBackground
        
        view.addSubview(lbl)
        view.addSubview(barView)
        barView.addSubview(collectionView)
        
        lbl.translatesAutoresizingMaskIntoConstraints = false
        barView.translatesAutoresizingMaskIntoConstraints = false
        
        // Label constraints
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            lbl.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            lbl.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])

        // Collection View constraints within barView
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: barView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: barView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: barView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: barView.trailingAnchor)
        ])
        
        // Vertical constraints
        let topConstraint = barView.topAnchor.constraint(equalTo: view.topAnchor)
        let bottomConstraint = barView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        barLeadingConstraint = barView.leadingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.trailingAnchor,
            constant: 0
        )
        let trailingConstraint = barView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        verticalConstraints = [topConstraint, bottomConstraint, barLeadingConstraint, trailingConstraint]
        // Bottom constraints
        bottomConstraints = [
            barView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
            barView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            barView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            ),
            barView.heightAnchor.constraint(equalToConstant: 80)
        ]

        // Default to bottom constraints
        refreshBarPosition()
    }
    
    // MARK: - Bar Layout

    private func refreshBarPosition(animated: Bool = true) {
        let manager = HingeTabBarManager.shared

        let isVertical: Bool
        if !manager.isFoldablePhone {
            isVertical = true
        } else if manager.hingeStatus == .closed {
            isVertical = true
            switch manager.orientation {
            case .landscapeRight:
                barLeadingConstraint.constant = -80
            default:
                barLeadingConstraint.constant = 0
            }
        } else {
            switch manager.orientation {
            case .landscapeRight, .landscapeLeft:
                isVertical = true
                barLeadingConstraint.constant = 0
            default:
                isVertical = false
            }
        }

        if isVertical {
            NSLayoutConstraint.deactivate(bottomConstraints)
            NSLayoutConstraint.activate(verticalConstraints)
            collectionViewLayout.scrollDirection = .vertical
            if manager.hingeStatus == .closed {
                switch manager.orientation {
                case .landscapeRight:
                    collectionViewLayout.sectionInset = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
                case .landscapeLeft:
                    collectionViewLayout.sectionInset = UIEdgeInsets(top: 6, left: 8, bottom: 80, right: 8)
                default:
                    collectionViewLayout.sectionInset = UIEdgeInsets(top: 160, left: 8, bottom: 6, right: 8)
                }
            } else {
                collectionViewLayout.sectionInset = UIEdgeInsets(top: 120, left: 8, bottom: 6, right: 8)
            }
        } else {
            NSLayoutConstraint.deactivate(verticalConstraints)
            NSLayoutConstraint.activate(bottomConstraints)
            collectionViewLayout.scrollDirection = .horizontal
            collectionViewLayout.sectionInset = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        }
        
        let animations = {
            self.view.layoutIfNeeded()
            self.collectionViewLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
        
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: animations
            )
        } else {
            animations()
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BarItemCell.reuseIdentifier,
            for: indexPath
        ) as? BarItemCell else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.item]
        cell.configure(with: item)
        cell.isItemSelected = indexPath.item == selectedItemIndex
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }

        let previousIndex = selectedItemIndex
        selectedItemIndex = indexPath.item

        let pathsToReload = [
            IndexPath(item: previousIndex, section: 0),
            indexPath
        ].filter { $0 != indexPath || previousIndex != indexPath.item }

        collectionView.reloadItems(at: pathsToReload)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
