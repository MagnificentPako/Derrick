((pla) => {
    var name = "fix_this_shit"

    var predicates = () => {
        return {
            'fixed_for_you/3': (thread, point, atom) => {
                var element = atom.args[0], prop = atom.args[1], val = atom.args[2]
				if( pla.type.is_variable( element ) || pla.type.is_variable( prop ) ) {
					thread.throw_error( pla.error.instantiation( atom.indicator ) );
				}  else if( !pla.type.is_atom( prop ) ) {
					thread.throw_error( pla.error.type( "atom", prop, atom.indicator ) );
				} else if( !pla.type.is_variable( val ) && !pla.type.is_atomic( val ) ) {
					thread.throw_error( pla.error.type( "atomic", val, atom.indicator ) );
				} else {
                    var value = new pla.type.Term(element['id'][prop.id])
                    thread.prepend( [new pla.type.State( point.goal.replace( new pla.type.Term( "=", [value, val] ) ), point.substitution, point )] );
				}
            }
        }
    }

    var exports = ['fixed_for_you/3']

    new pla.type.Module(name, predicates(), exports)
})(pl)

window.onload = () => {
    var session = pl.create()
    fetch("/static/app.pl")
        .then(response => response.text())
        .then(program => session.consult(program, {
            success: () => session.query("init.", {
                success: () => session.answer(console.log),
                error: (err) => console.log(err)
    })}))
}