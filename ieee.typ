// This function gets your whole document as its `body` and formats
// it as an article in the style of the IEEE.
#let ieee(
  // The paper's title.
  title: "Paper Title",
  sub_title: none,

  // An array of authors. For each author you can specify a name,
  // department, organization, location, and email. Everything but
  // but the name is optional.
  authors: (),

  // Date of submission for the paper.
  date_of_submission: none,

  // The paper's abstract. Can be omitted if you don't have one.
  abstract: none,

  // A list of index terms to display after the abstract.
  index-terms: (),

  // The article's paper size. Also affects the margins.
  paper-size: "us-letter",

  // The path to a bibliography file if you want to cite some external
  // works.
  bibliography-file: none,

  // Custom header options.
  header-left: "Assignment 1",
  header-center: none,
  header-right: "Swinburne University of Technology",

  // Custom footer options.
  footer-left: none,
  footer-center: auto,
  footer-right: none,

  // The paper's content.
  body
) = {
  // Set document metdata.
  set document(title: title, author: authors.map(author => author.name))

  // Set the body font.
  set text(font: "TeX Gyre Termes", size: 9pt, spacing: .35em)
  set enum(numbering: "1)a)i)")
  // Configure the page.
  set page(
    paper: paper-size,
    // Set the footer
    footer: context {
      if counter(page).get().first() > 1 and counter("appendix").get().first() == 0 {
        let l-val = if footer-left != none { footer-left } else { [] }
        let c-val = if footer-center == auto {
          counter(page).display("1")
        } else if footer-center != none {
          footer-center
        } else {
          []
        }
        let r-val = if footer-right != none { footer-right } else { [] }

        grid(
          columns: (1fr, 1fr, 1fr),
          align(left, l-val),
          align(center, c-val),
          align(right, r-val),
        )
      }
    },
    // Set the header
    header: context {
      if counter(page).get().first() > 1 and counter("appendix").get().first() == 0 {
        let l-val = if header-left != none { header-left } else { [] }
        let c-val = if header-center != none { header-center } else { [] }
        let r-val = if header-right != none { header-right } else { [] }

        grid(
          columns: (1fr, 1fr, 1fr),
          align(left, l-val),
          align(center, c-val),
          align(right, r-val),
        )
      }
    },

    // The margins depend on the paper size.
    margin: if paper-size == "a4" {
      (x: 41.5pt, top: 80.51pt, bottom: 89.51pt)
    } else {
      (
        x: (50pt / 216mm) * 100%,
        top: (55pt / 279mm) * 100%,
        bottom: (64pt / 279mm) * 100%,
      )
    }
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.a)")
  show heading: it => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).get()
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(12pt, weight: 400) // ヘディングのフォントサイズを指定
    if it.level == 1 {
      // First-level headings are centered smallcaps.
      // We don't want to number the acknowledgment section.
      let is-ack = it.body in ([Acknowledgment], [Acknowledgement], [Acknowledgments], [Acknowledgements])
      set align(center)
      set text(if is-ack { 13pt } else { 14pt }) // ヘディング1のフォントサイズ指定
      show: block.with(above: 15pt, below: 13.75pt, sticky: true)
      show: smallcaps
      if it.numbering != none and not is-ack {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      it.body
    } else if it.level == 2 {
      // Second-level headings are run-ins.
      set par(first-line-indent: 0pt)
      set text(style: "italic")
      show: block.with(spacing: 20pt, sticky: true) // spacing: ヘディングのあとの行間スペース
      if it.numbering != none {
        numbering("A.", deepest)
        h(7pt, weak: true)
      }
      it.body
    } else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("a)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  }
  show ref.where(form: "normal"): set ref(supplement: it => {
    if it.func() == figure {
      if it.kind == table {
        "Table"
      } else {
        "Fig."
      }
    }
  })
  // Render figure captions as "Fig. <number>. <caption>" or "Table <number>. <caption>"
  show figure.where(kind: table): set block(breakable: true)
  show figure: fig => {
    show figure.caption: it => context box(
      align(left)[
        #if fig.kind == table [
          Table~#it.counter.display(). #it.body
        ] else [
          Fig.~#it.counter.display(). #it.body
        ]
      ]
    )
    fig
  }

  // Display the paper's title.
  v(3pt, weak: true)
  align(center, text(18pt, title))
  align(center, text(15pt, sub_title))

  // Display the date of submission if provided.
  if date_of_submission != none [
    #align(center, text(12pt, [Date of Submission: #date_of_submission]))
    #v(8.35mm, weak: true)
  ]

  // Display the authors list.
  for i in range(calc.ceil(authors.len() / 3)) {
    let end = calc.min((i + 1) * 3, authors.len())
    let is-last = authors.len() == end
    let slice = authors.slice(i * 3, end)
    grid(
      columns: slice.len() * (1fr,),
      gutter: 12pt,
      ..slice.map(author => align(center, {
        text(12pt, author.name)
        if "studentid" in author [
          \ #author.studentid
        ]
          if "class" in author [
          \ #emph(author.class)
        ]
        if "organization" in author [
          \ #emph(author.organization)
        ]
        if "location" in author [
          \ #author.location
        ]
        if "email" in author [
          \ #link("mailto:" + author.email)
        ]        
        if "signature" in author [
          \ #author.signature
        ]
      }))
    )

    if not is-last {
      v(16pt, weak: true)
    }
  }
  v(40pt, weak: true)

  // Start two column mode and configure paragraph properties.
  show: columns.with(1, gutter: 12pt)
  set par(justify: true, first-line-indent: 1em)

  // Display abstract and index terms.
  if abstract != none [
    #set text(weight: 700)
    #h(1em) _Abstract_---#abstract

    #if index-terms != () [
      #h(1em)_Index terms_---#index-terms.join(", ")
    ]
    #v(2pt)
  ]
  
  // Display the paper's contents.
  body

  // Display bibliography.
  if bibliography-file != none and read(bibliography-file).trim() != "" {
    show bibliography: set text(8pt)
    bibliography(bibliography-file, title: text(10pt)[References], style: "harvard-cite-them-right")
  }
}
