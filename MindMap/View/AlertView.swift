import UIKit

protocol AlertViewDelegate: AnyObject {
    func addNode(name: String)
    func closeAlert()
}

class AlertView:  UIView {

    let alertHeight = 150.0

    private var backgroundView = { () -> UIView in
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return container
    }()
    
    private var containerView = { () -> UIView in
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.backgroundViolet
        container.layer.cornerRadius = 8
        return container
    }()
    
    private lazy var stackView = { () -> UIStackView in
        let stackView = UIStackView(arrangedSubviews: [textField, addButtonContainer])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.backgroundColor = .clear
        stackView.spacing = 8.0
        return stackView
    }()
    
    private var titleLabel = { () -> UILabel in
        let label = UILabel()
        label.text = "Create your map 💡"
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var errorLabel = { () -> UILabel in
        let label = UILabel()
        label.text = " "
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10)
        label.textColor = UIColor.error
        label.translatesAutoresizingMaskIntoConstraints = false
       return label
    }()
    
    private var textField = { () -> CustomRoundedTextField in
        let textfield = CustomRoundedTextField()
        textfield.textColor = .white
        textfield.attributedPlaceholder = NSAttributedString(string: "Your idea...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.regularLight])
        textfield.translatesAutoresizingMaskIntoConstraints = false
        return textfield
    }()
        
    private var addButtonContainer = { () -> UIView in
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    
    private var addButton = { () -> UIButton in
        let button = UIButton()
        button.setImage(UIImage(named: "send"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addButtonDidTap), for: .touchUpInside)
        return button
    }()
    
    private var closeButton = { () -> UIButton in
        let button = UIButton()
        button.setImage(UIImage(named: "close"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonDidTap), for: .touchUpInside)
        return button
    }()
    
    weak var delegate: AlertViewDelegate?
    
    // MARK: Initialize
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        // adding shadow
        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = .zero
        layer.shadowRadius = 4
        
        // adding subviews
        addSubview(backgroundView)
        addButtonContainer.addSubview(addButton)
        backgroundView.addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(errorLabel)
        containerView.addSubview(stackView)
        containerView.addSubview(closeButton)
        
        setupConstraints()
    }
    
    @objc func addButtonDidTap() {
        addButton.rotate()
        // validating map's name
        if let text = textField.text, !text.isEmpty, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            if mapWithThisNameExist(name: text) {
                shakeTextField()
                errorLabel.text = "This map already exist"
            } else {
                textField.text = ""
                errorLabel.text = ""
                delegate?.addNode(name: text)
            }
        } else {
            shakeTextField()
            errorLabel.text = "Map name shouldn't be empty"
        }
    }
    
    func mapWithThisNameExist(name: String) -> Bool {
        do {
            let _ = try FileStorage().getFile(atPath: "\(name)\(String.mmdExtension)")
            return true
        } catch {
            return false
        }
    }
    
    
    @objc func closeButtonDidTap() {
        textField.text = ""
        delegate?.closeAlert()
    }
    
    private func shakeTextField() {
        let midX = textField.center.x
        let midY = textField.center.y
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.06
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: midX - 6, y: midY)
        animation.toValue = CGPoint(x: midX + 6, y: midY)
        textField.layer.add(animation, forKey: "position")
    }
    
    // MARK: Constraints
    private func setupConstraints() {
        //background view
        backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        backgroundView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true

        //container View
        containerView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: alertHeight).isActive = true
        
        // add button
        addButtonContainer.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        addButton.leftAnchor.constraint(equalTo: addButtonContainer.leftAnchor).isActive = true
        addButton.centerYAnchor.constraint(equalTo: addButtonContainer.centerYAnchor).isActive = true
        addButton.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        addButton.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        
        // title label
        titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 16).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -16).isActive = true
        
        // error label
        errorLabel.topAnchor.constraint(equalTo: titleLabel.topAnchor, constant: 24).isActive = true
        errorLabel.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 16).isActive = true
        errorLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -16).isActive = true
        
        // stackView
        stackView.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24).isActive = true
        stackView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 16).isActive = true
        stackView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -16).isActive = true
        stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16).isActive = true
        stackView.widthAnchor.constraint(equalToConstant: 310).isActive = true
        
        // close button
        closeButton.widthAnchor.constraint(equalToConstant: 16.0).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 16.0).isActive = true
        closeButton.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -16).isActive = true
        closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
    }
    
}

