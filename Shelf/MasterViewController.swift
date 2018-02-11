//
//  MasterViewController.swift
//  Shelf
//
//  Created by Markus Stöbe on 28.01.18.
//  Copyright © 2018 Markus Stöbe. All rights reserved.
//

import MobileCoreServices
import UIKit

class MasterViewController: UITableViewController, UIDropInteractionDelegate, UITableViewDragDelegate {

	var detailViewController: DetailViewController? = nil
	var objects = [String]()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		navigationItem.leftBarButtonItem = editButtonItem

		let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
		navigationItem.rightBarButtonItem = addButton
		if let split = splitViewController {
		    let controllers = split.viewControllers
		    detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
		}

		//UIDrag- & UIDropInteraction vorbereiten
		let dropInteraction = UIDropInteraction(delegate: self)
		self.tableView.addInteraction(dropInteraction)

		self.tableView.dragDelegate = self
	}

	override func viewWillAppear(_ animated: Bool) {
		//gespeicherte Texte laden
		self.objects = self.load()

		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}


	//******************************************************************************************************************
	//* MARK: - Disk-IO
	//******************************************************************************************************************
	func save(items:[String]) {
		let fileManager = FileManager.default
		guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last
		else {
				return
		}

		for item in items {
			let df = DateFormatter()
			df.locale    = Locale(identifier: "de_DE")
			df.dateStyle = .medium
			df.timeStyle = .short

			let path = documentsURL.appendingPathComponent("snippet"+df.string(from: Date())+".txt")
			print(path)
			do {
				try item.write(to: path, atomically: true, encoding: String.Encoding.utf8)
			}
			catch {
				print("error while saving to disk")
			}
		}
	}

	func load() -> [String] {
		var items = [String]()

		//preapare IO
		let fileManager = FileManager.default
		guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last
			else {
				return items
		}

		//load driectory entries
		var fileList = [String]()
		do {
			 fileList = try fileManager.contentsOfDirectory(atPath: documentsURL.path)
		} catch _ {
			print("error loading file-list")
			return items
		}

		//load files
		for file in fileList {
			let filePath = documentsURL.appendingPathComponent(file)
			do {
				let item = try String.init(contentsOf: filePath)
				items.append(item)
			}
			catch {
				print("error loading file")
			}
		}
		return items
	}

	//******************************************************************************************************************
	//* MARK: - UIDropInteractionDelegate
	//******************************************************************************************************************
	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		return session.hasItemsConforming(toTypeIdentifiers: [kUTTypePlainText as String])
	}

	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		return UIDropProposal(operation: .copy)
	}

	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		_ = session.loadObjects(ofClass: String.self, completion: { items in
			self.objects.append(contentsOf: items)
			self.save(items: items)
			self.tableView.reloadData()
		})
	}

	//******************************************************************************************************************
	//* MARK: - UIDragInteractionDelegate
	//******************************************************************************************************************
	func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		var items = [UIDragItem]()

		let selectedItem = self.objects[indexPath.row]
		let itemProvider = NSItemProvider(object: selectedItem as NSItemProviderWriting)
		let dragItem     = UIDragItem(itemProvider: itemProvider)
		items.append(dragItem)

		return items
	}


	//******************************************************************************************************************
	// MARK: - Segues
	//******************************************************************************************************************
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = tableView.indexPathForSelectedRow {
		        let object = objects[indexPath.row]
		        let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
		        controller.detailItem = object
		        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		        controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	//******************************************************************************************************************
	// MARK: - Table View
	//******************************************************************************************************************
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return objects.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		let object = objects[indexPath.row]
		cell.textLabel!.text = object
		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
		    objects.remove(at: indexPath.row)
		    tableView.deleteRows(at: [indexPath], with: .fade)
		} else if editingStyle == .insert {
		    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
		}
	}

	@objc
	func insertNewObject(_ sender: Any) {
		objects.insert("created string", at: 0)
		self.save(items: [objects[0]])
		let indexPath = IndexPath(row: 0, section: 0)
		tableView.insertRows(at: [indexPath], with: .automatic)
	}

}

